using System;
using System.Data;
using System.Data.SqlClient;
using System.Web;
using System.Web.Configuration;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebApplication1
{
    // 3.5 d: create a cart for my active address, see its products and remove products
    // (products are added from the business page). The session check is in Customer.master.
    public partial class CustomerCart : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
                ShowCart();
        }

        private int CustomerId { get { return (int)Session["user"]; } }

        // ================= Loading =================

        private void ShowCart()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            // h_CustomerProfile: my active address; h_MyActiveCart: the Active cart of that address
            SqlCommand profileFunc = new SqlCommand(
                "SELECT active_address, active_zone, dbo.h_MyActiveCart(@customer_id) AS cart_id "
              + "FROM dbo.h_CustomerProfile(@customer_id)", conn);
            profileFunc.Parameters.Add(new SqlParameter("@customer_id", CustomerId));

            DataTable profile = new DataTable();
            DataTable items = new DataTable();
            try
            {
                new SqlDataAdapter(profileFunc).Fill(profile);
                if (profile.Rows.Count > 0 && profile.Rows[0]["cart_id"] != DBNull.Value)
                {
                    // h_CartItems: the items of my cart with their prices
                    SqlCommand itemsFunc = new SqlCommand(
                        "SELECT * FROM dbo.h_CartItems(@cart_id) ORDER BY business_name, product_name", conn);
                    itemsFunc.Parameters.Add(new SqlParameter("@cart_id", (int)profile.Rows[0]["cart_id"]));
                    new SqlDataAdapter(itemsFunc).Fill(items);
                }
            }
            catch (SqlException)
            {
                ShowError("We could not load your cart right now. Please refresh the page in a moment.");
                return;
            }

            if (profile.Rows.Count == 0 || profile.Rows[0]["active_address"] == DBNull.Value)
            {
                addressLine.Text = "";
                ShowError("You need an address before you can shop. <a href=\"CustomerAddresses.aspx\">Add your address</a>.");
                noCartPanel.Visible = cartPanel.Visible = false;
                return;
            }

            DataRow p = profile.Rows[0];
            addressLine.Text = "For your active address <b>" + HttpUtility.HtmlEncode((string)p["active_address"]) + "</b> ("
                             + HttpUtility.HtmlEncode((string)p["active_zone"]) + ").";

            if (p["cart_id"] == DBNull.Value)
            {
                noCartPanel.Visible = true;
                cartPanel.Visible = false;
                return;
            }

            ViewState["cartId"] = (int)p["cart_id"];
            noCartPanel.Visible = false;
            cartPanel.Visible = true;
            itemsGrid.DataSource = items;
            itemsGrid.DataBind();

            decimal total = 0;
            foreach (DataRow row in items.Rows) total += (decimal)row["line_total"];
            subtotal.Text = total.ToString("N2");
            checkoutLink.Visible = items.Rows.Count > 0;
        }

        protected void itemsGrid_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType != DataControlRowType.DataRow) return;
            // A product that became unavailable blocks the checkout: point it out
            if (!(bool)DataBinder.Eval(e.Row.DataItem, "is_available"))
            {
                e.Row.FindControl("unavailable").Visible = true;
                e.Row.CssClass = "row-bad";
                ShowWarning("Some products in your cart are not available anymore. Remove them before checking out.");
            }
        }

        // ================= Create_Cart =================

        protected void create_Click(object sender, EventArgs e)
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand("Create_Cart", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@customer_id", CustomerId));

            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    ShowSuccess("Your cart is ready. <a href=\"CustomerBrowse.aspx\">Browse businesses</a> to add products.");
                    break;
                case -1:
                    ShowError("You need an active address before you can start a cart. <a href=\"CustomerAddresses.aspx\">Add an address</a>.");
                    break;
                case -2:
                    ShowError("You already have a cart for your active address. It is shown below.");
                    break;
                case -3:
                    ShowError("Your account is blacklisted, so you cannot start a cart. Contact support.");
                    return;
                default:
                    ShowCodeError(rc);
                    return;
            }
            ShowCart();
        }

        // ================= Remove_From_Cart =================

        protected void itemsGrid_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName != "RemoveItem" || ViewState["cartId"] == null) return;

            DataKey key = itemsGrid.DataKeys[Convert.ToInt32(e.CommandArgument)];
            string name = HttpUtility.HtmlEncode((string)key["product_name"]);

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            // The cart is my own active cart (from h_MyActiveCart), never chosen by the user
            SqlCommand proc = new SqlCommand("Remove_From_Cart", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@cart_id", (int)ViewState["cartId"]));
            proc.Parameters.Add(new SqlParameter("@product_id", (int)key["product_id"]));

            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    ShowSuccess(name + " was removed from your cart.");
                    break;
                case -1:
                    ShowError(name + " is not in your cart anymore. The cart has been refreshed.");
                    break;
                case -4:
                    ShowError("This cart cannot be changed anymore: it was checked out, or your active address changed. The cart has been refreshed.");
                    break;
                default:
                    ShowCodeError(rc);
                    return;
            }
            ShowCart();
        }

        // ================= Helpers =================

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

        private void ShowWarning(string text)
        {
            if (msg.Text != "") return;   // keep the result of an action visible
            msg.CssClass = "msg msg-warning";
            msg.Text = text;
        }

        private void ShowError(string text)
        {
            msg.CssClass = "msg msg-error";
            msg.Text = text;
        }
    }
}
