using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Text;
using System.Web;
using System.Web.Configuration;
using System.Web.UI.WebControls;

namespace WebApplication1
{
    // 3.5 e: check out my cart with a payment method and an optional voucher.
    // Before I confirm, I see how my total is built from each business, the delivery fees and the voucher discount.
    // The session check is in Customer.master (Page_Init), which runs before this page.
    public partial class CustomerCheckout : System.Web.UI.Page
    {
        private int CustomerId { get { return (int)Session["user"]; } }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (IsPostBack) return;
            try
            {
                LoadOptions();
                BuildBreakdown();
            }
            catch (SqlException)
            {
                ShowError("We could not load your checkout right now. Please refresh the page in a moment.");
                checkoutPanel.Visible = false;
            }
        }

        protected void options_Changed(object sender, EventArgs e)
        {
            msg.Text = "";
            try { BuildBreakdown(); }
            catch (SqlException) { ShowError("We could not update the total right now. Please try again in a moment."); }
        }

        // ================= Vouchers, cards, wallet =================

        private void LoadOptions()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            // h_MyVouchers: my vouchers that can still be used
            SqlCommand vouchersFunc = new SqlCommand(
                "SELECT voucher_id, promo_code, is_percentage, amount, expiry_date FROM dbo.h_MyVouchers(@customer_id) ORDER BY expiry_date", conn);
            vouchersFunc.Parameters.Add(new SqlParameter("@customer_id", CustomerId));
            // h_MyCards: my cards, last 4 digits only
            SqlCommand cardsFunc = new SqlCommand(
                "SELECT card_id, card_holder_name, last_four_digits, expiration_date FROM dbo.h_MyCards(@customer_id) ORDER BY expiration_date DESC", conn);
            cardsFunc.Parameters.Add(new SqlParameter("@customer_id", CustomerId));

            DataTable vouchers = new DataTable();
            DataTable cards = new DataTable();
            new SqlDataAdapter(vouchersFunc).Fill(vouchers);
            new SqlDataAdapter(cardsFunc).Fill(cards);

            voucher.Items.Clear();
            voucher.Items.Add(new ListItem("No voucher", ""));
            foreach (DataRow v in vouchers.Rows)
                voucher.Items.Add(new ListItem((string)v["promo_code"] + " - " + VoucherText(v), v["voucher_id"].ToString()));

            card.Items.Clear();
            int expired = 0;
            foreach (DataRow c in cards.Rows)
            {
                if ((DateTime)c["expiration_date"] < DateTime.Today) { expired++; continue; }   // an expired card cannot pay
                card.Items.Add(new ListItem("•••• " + (string)c["last_four_digits"] + " - "
                    + (string)c["card_holder_name"] + " (expires " + ((DateTime)c["expiration_date"]).ToString("MM/yyyy") + ")",
                    c["card_id"].ToString()));
            }
            cardHint.Text = card.Items.Count == 0
                ? "You have no valid card. <a href=\"CustomerCards.aspx\">Save a card</a> or pay another way."
                : expired > 0 ? expired + " expired card(s) are not shown." : "";
        }

        private static string VoucherText(DataRow v)
        {
            decimal amount = (decimal)v["amount"];
            return (bool)v["is_percentage"] ? amount.ToString("0.##") + "% off your products" : amount.ToString("N2") + " EGP off";
        }

        // ================= The breakdown =================

        // Shows how the total is built. Returns false if there is nothing to check out.
        private bool BuildBreakdown()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            // h_CustomerProfile + h_MyActiveCart + h_ZoneList: my address, wallet, cart and the zone's delivery fee
            SqlCommand profileFunc = new SqlCommand(
                "SELECT p.active_address, p.active_zone, p.wallet_balance, z.delivery_fee, dbo.h_MyActiveCart(@customer_id) AS cart_id "
              + "FROM dbo.h_CustomerProfile(@customer_id) p LEFT JOIN h_ZoneList z ON z.zone_id = p.active_zone_id", conn);
            profileFunc.Parameters.Add(new SqlParameter("@customer_id", CustomerId));
            DataTable profile = new DataTable();
            new SqlDataAdapter(profileFunc).Fill(profile);

            if (profile.Rows.Count == 0 || profile.Rows[0]["cart_id"] == DBNull.Value)
            {
                ShowError("You have no cart for your active address. <a href=\"CustomerCart.aspx\">Go to my cart</a> to start one.");
                checkoutPanel.Visible = false;
                return false;
            }
            DataRow p = profile.Rows[0];
            int cartId = (int)p["cart_id"];
            decimal zoneFee = (decimal)p["delivery_fee"];
            decimal walletBalance = (decimal)p["wallet_balance"];
            string zone = (string)p["active_zone"];
            ViewState["cartId"] = cartId;

            addressLine.Text = "Delivering to <b>" + HttpUtility.HtmlEncode((string)p["active_address"]) + "</b> ("
                             + HttpUtility.HtmlEncode(zone) + ").";
            walletLine.Text = "Your wallet balance is " + walletBalance.ToString("N2") + " EGP.";

            // h_CartItems: my products with their prices
            SqlCommand itemsFunc = new SqlCommand(
                "SELECT * FROM dbo.h_CartItems(@cart_id) ORDER BY business_name, product_name", conn);
            itemsFunc.Parameters.Add(new SqlParameter("@cart_id", cartId));
            DataTable items = new DataTable();
            new SqlDataAdapter(itemsFunc).Fill(items);

            if (items.Rows.Count == 0)
            {
                ShowError("Your cart is empty. Add products before checking out. <a href=\"CustomerBrowse.aspx\">Browse businesses</a>");
                checkoutPanel.Visible = false;
                return false;
            }

            // h_BusinessDetails of each business in my cart: open now, status and zone
            SqlCommand businessCmd = new SqlCommand(
                "SELECT d.business_id, d.business_name, d.zone_name, d.status, d.is_open_now "
              + "FROM (SELECT DISTINCT business_id FROM dbo.h_CartItems(@cart_id)) c "
              + "CROSS APPLY dbo.h_BusinessDetails(c.business_id) d ORDER BY d.business_name", conn);
            businessCmd.Parameters.Add(new SqlParameter("@cart_id", cartId));
            DataTable businesses = new DataTable();
            new SqlDataAdapter(businessCmd).Fill(businesses);

            // ---- Totals (the same rules Checkout_Cart uses) ----
            decimal subtotal = 0;
            foreach (DataRow i in items.Rows) subtotal += (decimal)i["line_total"];
            decimal fees = businesses.Rows.Count * zoneFee;

            // Calculate_Voucher_Discount
            object voucherId = voucher.SelectedValue == "" ? (object)DBNull.Value : Convert.ToInt32(voucher.SelectedValue);
            SqlCommand discountFunc = new SqlCommand("SELECT dbo.Calculate_Voucher_Discount(@voucher_id, @subtotal)", conn);
            discountFunc.Parameters.Add(new SqlParameter("@voucher_id", voucherId));
            discountFunc.Parameters.Add(new SqlParameter("@subtotal", SqlDbType.Decimal) { Precision = 10, Scale = 2, Value = subtotal });
            decimal discount;
            try
            {
                conn.Open();
                discount = (decimal)discountFunc.ExecuteScalar();
            }
            finally
            {
                conn.Close();
            }
            decimal total = subtotal + fees - discount;
            ViewState["total"] = total;

            // ---- The breakdown, one block per business ----
            StringBuilder html = new StringBuilder("<table class=\"bill\">");
            problemsList.Items.Clear();
            foreach (DataRow b in businesses.Rows)
            {
                int businessId = (int)b["business_id"];
                string bname = HttpUtility.HtmlEncode((string)b["business_name"]);
                decimal part = 0;
                html.Append("<tr class=\"bill-business\"><td colspan=\"2\">" + bname + "</td></tr>");
                foreach (DataRow i in items.Rows)
                {
                    if ((int)i["business_id"] != businessId) continue;
                    part += (decimal)i["line_total"];
                    html.Append("<tr><td>" + i["quantity"] + " &times; " + HttpUtility.HtmlEncode((string)i["product_name"])
                              + " <span class=\"muted\">(" + ((decimal)i["unit_price"]).ToString("N2") + " each)</span></td>"
                              + "<td class=\"num\">" + ((decimal)i["line_total"]).ToString("N2") + "</td></tr>");
                    if (!(bool)i["is_available"])
                        // (a BulletedList encodes its items itself)
                        problemsList.Items.Add((string)i["product_name"] + " is not available anymore. Remove it from your cart.");
                }
                html.Append("<tr><td class=\"muted\">Delivery fee for this business</td><td class=\"num\">" + zoneFee.ToString("N2") + "</td></tr>");
                html.Append("<tr class=\"bill-sub\"><td>" + bname + " total</td><td class=\"num\">" + (part + zoneFee).ToString("N2") + "</td></tr>");

                // Things that would stop the checkout, in the customer's words
                string name = (string)b["business_name"];
                if ((string)b["status"] != "Active")
                    problemsList.Items.Add(name + " is not taking orders right now. Remove its products from your cart.");
                else if (!Convert.ToBoolean(b["is_open_now"]))
                    problemsList.Items.Add(name + " is closed now. Check out when it is open, or remove its products.");
                if ((string)b["zone_name"] != zone)
                    problemsList.Items.Add(name + " does not deliver to " + zone + ". Remove its products or change your active address.");
            }

            html.Append("<tr class=\"bill-gap\"><td colspan=\"2\"></td></tr>");
            html.Append("<tr><td>Products</td><td class=\"num\">" + subtotal.ToString("N2") + "</td></tr>");
            html.Append("<tr><td>Delivery fees <span class=\"muted\">(" + businesses.Rows.Count + " business(es) &times; "
                      + zoneFee.ToString("N2") + ")</span></td><td class=\"num\">" + fees.ToString("N2") + "</td></tr>");
            if (voucherId != DBNull.Value)
                html.Append("<tr class=\"bill-discount\"><td>Voucher " + HttpUtility.HtmlEncode(voucher.SelectedItem.Text)
                          + "</td><td class=\"num\">&minus; " + discount.ToString("N2") + "</td></tr>");
            html.Append("<tr class=\"bill-total\"><td>Total to pay</td><td class=\"num\">" + total.ToString("N2") + " EGP</td></tr>");
            html.Append("</table>");

            // Why: each business delivers its part separately
            html.Append("<p class=\"muted\">Each business delivers its part separately, so the " + HttpUtility.HtmlEncode(zone)
                      + " delivery fee of " + zoneFee.ToString("N2") + " EGP is paid once for each business in your cart."
                      + (voucherId != DBNull.Value ? " The voucher applies to the products only, not to the delivery fees." : "") + "</p>");
            breakdown.Text = html.ToString();

            // ---- Payment checks ----
            cardPanel.Visible = method.SelectedValue == "Card";
            if (method.SelectedValue == "Wallet" && walletBalance < total)
                problemsList.Items.Add("Your wallet balance (" + walletBalance.ToString("N2") + " EGP) is less than the total ("
                                     + total.ToString("N2") + " EGP). Choose Cash or Card.");
            if (method.SelectedValue == "Card" && card.Items.Count == 0)
                problemsList.Items.Add("You have no valid card. Save a card or choose Cash or Wallet.");
            problemsList.Visible = problemsList.Items.Count > 0;

            placeBtn.Text = "Place order and pay " + total.ToString("N2") + " EGP";
            placeBtn.OnClientClick = "return confirm('Place your order and pay " + total.ToString("N2") + " EGP by "
                                   + method.SelectedItem.Text.ToLower() + "?');";
            return true;
        }

        // ================= Checkout_Cart =================

        protected void place_Click(object sender, EventArgs e)
        {
            // Rebuild first so the checks and the cart are the current ones
            try
            {
                if (!BuildBreakdown()) return;
            }
            catch (SqlException)
            {
                ShowCodeError(int.MinValue);
                return;
            }

            string payMethod = method.SelectedValue;
            if (payMethod == "Card" && card.SelectedValue == "")
            {
                ShowError("Choose the card to pay with, or choose Cash or Wallet.");
                return;
            }

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand("Checkout_Cart", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@cart_id", (int)ViewState["cartId"]));
            proc.Parameters.Add(new SqlParameter("@voucher_id", voucher.SelectedValue == "" ? (object)DBNull.Value : Convert.ToInt32(voucher.SelectedValue)));
            proc.Parameters.Add(new SqlParameter("@payment_method", payMethod));
            proc.Parameters.Add(new SqlParameter("@card_id", payMethod == "Card" ? (object)Convert.ToInt32(card.SelectedValue) : DBNull.Value));

            decimal total = (decimal)ViewState["total"];
            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    ShowSuccess("Your order was placed. You " + (payMethod == "Cash" ? "will pay " : "paid ") + total.ToString("N2")
                              + " EGP by " + method.SelectedItem.Text.ToLower() + ". A rider is assigned to each part of your order.");
                    checkoutPanel.Visible = false;
                    donePanel.Visible = true;
                    break;
                case -1:
                    ShowError("This voucher cannot be used anymore (it may have expired). Choose another voucher or no voucher.");
                    ReloadOptions();
                    break;
                case -3:
                    ShowError(voucher.SelectedValue != ""
                        ? "This voucher does not belong to you, or your account is blacklisted. Choose another voucher, or contact support."
                        : "Your account is blacklisted, so you cannot check out. Contact support.");
                    break;
                case -4:
                    ShowError(problemsList.Items.Count > 0
                        ? "Your order cannot be placed yet. Fix the problems listed under the total, then try again."
                        : "Your order cannot be placed: the voucher was already used, or your cart changed. Choose another voucher and try again.");
                    ReloadOptions();
                    break;
                case -5:
                    ShowError("Some products come from a business that does not deliver to your active address. "
                            + "Remove them from your cart or change your active address.");
                    break;
                case -7:
                    ShowError(payMethod == "Wallet"
                        ? "Your wallet balance is not enough for " + total.ToString("N2") + " EGP. Choose Cash or Card."
                        : "This card cannot be used (it may have expired). Choose another card, or pay by Cash or Wallet.");
                    break;
                case -8:
                    ShowError("No rider is available in your zone right now. Try again in a few minutes.");
                    break;
                case -9:
                    ShowError("Your cart is empty. Add products before checking out.");
                    break;
                default:
                    ShowCodeError(rc);
                    break;
            }
        }

        private void ReloadOptions()
        {
            try
            {
                LoadOptions();
                BuildBreakdown();
            }
            catch (SqlException) { }
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

        private void ShowError(string text)
        {
            msg.CssClass = "msg msg-error";
            msg.Text = text;
        }
    }
}
