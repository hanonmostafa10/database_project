using System;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Web;
using System.Web.Configuration;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebApplication1
{
    // 3.2 e (issue a voucher, view active vouchers) and 3.2 f (blacklist a customer, lift my blacklist)
    // The session check is in Admin.master (Page_Init), which runs before this page.
    public partial class AdminCustomers : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                expiryDate.Text = DateTime.Today.AddMonths(1).ToString("yyyy-MM-dd");
                BindAll();
            }
        }

        // ================= Loading the lists =================

        private void BindAll()
        {
            try
            {
                BindCustomerLists();
                BindVouchers();
                BindBlacklist();
            }
            catch (SqlException)
            {
                ShowError("We could not load the customers right now. Please refresh the page in a moment.");
            }
        }

        // h_CustomerList: customers to choose from (by name), only those who are not blacklisted
        private void BindCustomerLists()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand customersView = new SqlCommand(
                "SELECT customer_id, customer_name, username, active_zone FROM h_CustomerList "
              + "WHERE account_status = 'Active' ORDER BY customer_name", conn);

            voucherCustomer.Items.Clear();
            blacklistCustomer.Items.Clear();
            voucherCustomer.Items.Add(new ListItem("-- Choose a customer --", ""));
            blacklistCustomer.Items.Add(new ListItem("-- Choose a customer --", ""));

            try
            {
                conn.Open();
                SqlDataReader rdr = customersView.ExecuteReader();
                while (rdr.Read())
                {
                    string text = rdr.GetString(1) + " (" + rdr.GetString(2) + ")";
                    if (!rdr.IsDBNull(3)) text += " - " + rdr.GetString(3);
                    string id = rdr.GetInt32(0).ToString();
                    voucherCustomer.Items.Add(new ListItem(text, id));
                    blacklistCustomer.Items.Add(new ListItem(text, id));
                }
                rdr.Close();
            }
            finally
            {
                conn.Close();
            }
        }

        // ActiveVouchers, with the customer's name from h_CustomerList
        private void BindVouchers()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand vouchersView = new SqlCommand(
                "SELECT v.promo_code, c.customer_name, "
              + "CASE WHEN v.is_percentage = 1 THEN FORMAT(v.amount, '0.##') + '%' "
              + "ELSE FORMAT(v.amount, 'N2') + ' EGP' END AS discount, v.expiry_date "
              + "FROM ActiveVouchers v LEFT JOIN h_CustomerList c ON c.customer_id = v.customer_id "
              + "ORDER BY v.expiry_date, v.promo_code", conn);

            DataTable rows = new DataTable();
            new SqlDataAdapter(vouchersView).Fill(rows);
            vouchersGrid.DataSource = rows;
            vouchersGrid.DataBind();
        }

        // h_BlacklistedCustomers: the reason and the admin who can lift it
        private void BindBlacklist()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand blacklistView = new SqlCommand(
                "SELECT customer_id, customer_name, reason, admin_id, blacklisted_by FROM h_BlacklistedCustomers "
              + "ORDER BY customer_name", conn);

            DataTable rows = new DataTable();
            new SqlDataAdapter(blacklistView).Fill(rows);
            blacklistGrid.DataSource = rows;
            blacklistGrid.DataBind();
        }

        protected void blacklistGrid_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType != DataControlRowType.DataRow) return;

            // I can only lift a blacklist that I set
            bool mine = (int)DataBinder.Eval(e.Row.DataItem, "admin_id") == (int)Session["user"];
            e.Row.FindControl("liftBtn").Visible = mine;
            e.Row.FindControl("notMine").Visible = !mine;
        }

        // ================= 3.2 e: Issue_Voucher =================

        protected void issue_Click(object sender, EventArgs e)
        {
            string code = promoCode.Text.Trim();
            bool isPercentage = discountType.SelectedValue == "1";
            decimal amount;
            DateTime expiry;

            // Check the input before calling the database
            if (voucherCustomer.SelectedValue == "")
            {
                ShowError("Please choose the customer who gets the voucher.");
                return;
            }
            if (code == "")
            {
                ShowError("Please enter a promo code, for example SUMMER10.");
                return;
            }
            if (!decimal.TryParse(voucherAmount.Text.Trim(), NumberStyles.Number, CultureInfo.InvariantCulture, out amount) || amount <= 0 || amount > 99999999.99m)
            {
                ShowError("Please enter a discount amount greater than 0.");
                return;
            }
            if (isPercentage && (amount < 1 || amount > 100))
            {
                ShowError("A percentage discount must be between 1 and 100%. Enter a smaller amount or choose a fixed amount.");
                return;
            }
            if (!DateTime.TryParseExact(expiryDate.Text.Trim(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out expiry))
            {
                ShowError("Please pick the expiry date from the calendar.");
                return;
            }
            if (expiry < DateTime.Today)
            {
                ShowError("The expiry date is in the past. Pick today or a later date.");
                return;
            }

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand("Issue_Voucher", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@customer_id", Convert.ToInt32(voucherCustomer.SelectedValue)));
            proc.Parameters.Add(new SqlParameter("@promo_code", code));
            proc.Parameters.Add(new SqlParameter("@is_percentage", isPercentage));
            proc.Parameters.Add(new SqlParameter("@amount", amount));
            proc.Parameters.Add(new SqlParameter("@expiry_date", expiry));
            proc.Parameters.Add(new SqlParameter("@admin_id", (int)Session["user"]));

            string customer = HttpUtility.HtmlEncode(NameOnly(voucherCustomer.SelectedItem.Text));
            string safeCode = HttpUtility.HtmlEncode(code);

            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    ShowSuccess("The voucher " + safeCode + " was issued to " + customer + ".");
                    promoCode.Text = "";
                    voucherAmount.Text = "";
                    voucherCustomer.SelectedIndex = 0;
                    break;
                case -1:
                    ShowError("The voucher details are not valid. The amount must be more than 0 (1 to 100 for a percentage) "
                            + "and the expiry date cannot be in the past.");
                    break;
                case -2:
                    ShowError("The promo code " + safeCode + " already exists. Choose another code.");
                    break;
                case -3:
                    ShowError(customer + " is blacklisted, so they cannot get vouchers. Lift the blacklist first.");
                    break;
                default:
                    ShowCodeError(rc);
                    return;
            }
            BindAll();
        }

        // ================= 3.2 f: Blacklist_Customer =================

        protected void blacklist_Click(object sender, EventArgs e)
        {
            string reason = blacklistReason.Text.Trim();

            if (blacklistCustomer.SelectedValue == "")
            {
                ShowError("Please choose the customer to blacklist.");
                return;
            }
            if (reason == "")
            {
                ShowError("Please write the reason for the blacklist. Other admins will see it.");
                return;
            }

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand("Blacklist_Customer", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@customer_id", Convert.ToInt32(blacklistCustomer.SelectedValue)));
            proc.Parameters.Add(new SqlParameter("@admin_id", (int)Session["user"]));
            proc.Parameters.Add(new SqlParameter("@reason", reason));

            string customer = HttpUtility.HtmlEncode(NameOnly(blacklistCustomer.SelectedItem.Text));

            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    ShowSuccess(customer + " was blacklisted. Their orders that were not picked up yet were cancelled and refunded, "
                              + "and their unused vouchers were deleted.");
                    blacklistReason.Text = "";
                    break;
                case -1:
                    ShowError("Please choose a customer and write the reason for the blacklist.");
                    break;
                case -3:
                    ShowError("You can only blacklist customers who have an address in your zone ("
                            + HttpUtility.HtmlEncode((string)Session["zoneName"]) + "). Ask a Super Admin.");
                    break;
                case -4:
                    ShowError(customer + " is already blacklisted.");
                    break;
                default:
                    ShowCodeError(rc);
                    return;
            }
            BindAll();
        }

        // ================= 3.2 f: Lift_Customer_Blacklist =================

        protected void blacklistGrid_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName != "Lift") return;

            int index = Convert.ToInt32(e.CommandArgument);
            int customerId = (int)blacklistGrid.DataKeys[index]["customer_id"];
            string customer = HttpUtility.HtmlEncode((string)blacklistGrid.DataKeys[index]["customer_name"]);

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand("Lift_Customer_Blacklist", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@customer_id", customerId));
            proc.Parameters.Add(new SqlParameter("@admin_id", (int)Session["user"]));

            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    ShowSuccess("The blacklist on " + customer + " was lifted. They can log in and order again.");
                    break;
                case -3:
                    ShowError("Only the admin who blacklisted " + customer + " can lift it.");
                    break;
                case -4:
                    ShowError(customer + " is not blacklisted anymore. The list has been refreshed.");
                    break;
                default:
                    ShowCodeError(rc);
                    return;
            }
            BindAll();
        }

        // ================= Helpers =================

        // "Mona Ali (mona.ali) - Maadi" -> "Mona Ali"
        private static string NameOnly(string listText)
        {
            int i = listText.IndexOf(" (");
            return i > 0 ? listText.Substring(0, i) : listText;
        }

        // Runs a Milestone 2 procedure and returns its RETURN code (int.MinValue if the database failed)
        private int RunProcedure(SqlCommand proc)
        {
            SqlParameter returnCode = proc.Parameters.Add("@return", SqlDbType.Int);
            returnCode.Direction = ParameterDirection.ReturnValue;
            try
            {
                proc.Connection.Open();
                proc.ExecuteNonQuery();
            }
            catch (SqlException)
            {
                return int.MinValue;
            }
            finally
            {
                proc.Connection.Close();
            }
            return Convert.ToInt32(returnCode.Value);
        }

        private void ShowCodeError(int code)
        {
            if (code == int.MinValue)
                ShowError("We could not reach the database right now. Please try again in a moment.");
            else
                ShowError("This action could not be completed. Refresh the page and try again.");
        }

        private void ShowSuccess(string text)
        {
            msg.CssClass = "msg msg-success";
            msg.Text = text;
        }

        private void ShowError(string text)
        {
            msg.CssClass = "msg msg-error";
            msg.Text = text;
        }
    }
}
