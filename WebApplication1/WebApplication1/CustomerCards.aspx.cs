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
    // 3.5 c: save a card; only the last 4 digits of a card number are ever shown
    // The session check is in Customer.master (Page_Init), which runs before this page.
    public partial class CustomerCards : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                holderName.Text = (string)Session["name"] ?? "";
                BindCards();
            }
        }

        // h_MyCards: my cards with the last 4 digits only
        private void BindCards()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand cardsFunc = new SqlCommand(
                "SELECT card_id, card_holder_name, last_four_digits, expiration_date FROM dbo.h_MyCards(@customer_id) "
              + "ORDER BY expiration_date DESC", conn);
            cardsFunc.Parameters.Add(new SqlParameter("@customer_id", (int)Session["user"]));

            DataTable rows = new DataTable();
            try
            {
                new SqlDataAdapter(cardsFunc).Fill(rows);
            }
            catch (SqlException)
            {
                ShowError("We could not load your cards right now. Please refresh the page in a moment.");
                return;
            }
            cardsGrid.DataSource = rows;
            cardsGrid.DataBind();
        }

        protected void cardsGrid_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType != DataControlRowType.DataRow) return;
            if ((DateTime)DataBinder.Eval(e.Row.DataItem, "expiration_date") < DateTime.Today)
            {
                Label badge = (Label)e.Row.FindControl("expiredBadge");
                badge.Text = "Expired - cannot be used";
                badge.CssClass = "status status-Suspended";
            }
        }

        // ================= Add_Card =================

        protected void save_Click(object sender, EventArgs e)
        {
            // Read the number, then clear the box so the full number is never sent back to the page
            string number = cardNo.Text.Replace(" ", "").Replace("-", "").Trim();
            cardNo.Text = "";
            string holder = holderName.Text.Trim();
            DateTime month;

            // Check the input before calling the database
            if (number.Length != 16 || !IsDigits(number))
            {
                ShowError("The card number must be exactly 16 digits. Type it again.");
                return;
            }
            if (holder == "")
            {
                ShowError("Please enter the name written on the card. Type the card number again.");
                return;
            }
            if (!DateTime.TryParseExact(expiry.Text.Trim(), "yyyy-MM", CultureInfo.InvariantCulture, DateTimeStyles.None, out month))
            {
                ShowError("Please choose the month and year the card expires. Type the card number again.");
                return;
            }
            // A card is valid until the last day of its expiry month
            DateTime expires = month.AddMonths(1).AddDays(-1);
            if (expires < DateTime.Today)
            {
                ShowError("This card has expired. Use a card that is still valid.");
                return;
            }

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand("Add_Card", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@customer_id", (int)Session["user"]));
            proc.Parameters.Add(new SqlParameter("@card_no", number));
            proc.Parameters.Add(new SqlParameter("@card_holder_name", holder));
            proc.Parameters.Add(new SqlParameter("@expiration_date", SqlDbType.Date) { Value = expires });

            string last4 = number.Substring(12);
            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    ShowSuccess("Your card ending in " + last4 + " was saved. You can pay with it at checkout.");
                    expiry.Text = "";
                    break;
                case -1:
                    ShowError("The card details are not valid. Check the 16-digit number, the name and that the card has not expired.");
                    return;
                case -2:
                    ShowError("You already saved the card ending in " + last4 + ".");
                    return;
                case -3:
                    ShowError("Only a customer can save cards.");
                    return;
                default:
                    ShowCodeError(rc);
                    return;
            }
            BindCards();
        }

        // ================= Helpers =================

        private static bool IsDigits(string s)
        {
            foreach (char c in s)
                if (c < '0' || c > '9') return false;
            return true;
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
