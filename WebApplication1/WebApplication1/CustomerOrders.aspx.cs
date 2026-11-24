using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Web;
using System.Web.Configuration;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebApplication1
{
    // 3.6 c (my orders: where is each part, when will it arrive), 3.6 d (cancel, reorder),
    // 3.6 e (feedback for a delivered part, rate its rider)
    // The session check is in Customer.master (Page_Init), which runs before this page.
    public partial class CustomerOrders : System.Web.UI.Page
    {
        private int CustomerId { get { return (int)Session["user"]; } }

        // Real average delivery time (minutes) of each zone, from ZoneDeliveryPerformance
        private Dictionary<string, decimal> zoneAvg = new Dictionary<string, decimal>();
        // The order being shown while its parts are bound
        private decimal? currentZoneAvg;
        private DateTime currentOrderDate;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
                BindOrders();
        }

        // ================= Loading =================

        private void BindOrders()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            // My_Order_History: orders on the way first, then the newest
            SqlCommand historyFunc = new SqlCommand(
                "SELECT * FROM dbo.My_Order_History(@customer_id) "
              + "ORDER BY CASE WHEN status IN ('Placed', 'In Progress') THEN 0 ELSE 1 END, order_date DESC", conn);
            historyFunc.Parameters.Add(new SqlParameter("@customer_id", CustomerId));
            // ZoneDeliveryPerformance: the zones' real delivery times, used for the estimated arrival
            SqlCommand zoneView = new SqlCommand("SELECT zone_name, avg_tracking_time FROM ZoneDeliveryPerformance", conn);

            DataTable orders = new DataTable();
            DataTable zones = new DataTable();
            try
            {
                new SqlDataAdapter(historyFunc).Fill(orders);
                new SqlDataAdapter(zoneView).Fill(zones);
            }
            catch (SqlException)
            {
                ShowError("We could not load your orders right now. Please refresh the page in a moment.");
                return;
            }

            zoneAvg.Clear();
            foreach (DataRow z in zones.Rows)
                if (z["avg_tracking_time"] != DBNull.Value)
                    zoneAvg[(string)z["zone_name"]] = (decimal)z["avg_tracking_time"];

            noOrders.Visible = orders.Rows.Count == 0;
            try
            {
                ordersRepeater.DataSource = orders;
                ordersRepeater.DataBind();
            }
            catch (SqlException)
            {
                ShowError("We could not load the parts of your orders right now. Please refresh the page in a moment.");
            }
        }

        // h_OrderSubOrders: the parts of an order with their rider, times and progress
        private DataTable ReadParts(int orderId)
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand partsFunc = new SqlCommand(
                "SELECT * FROM dbo.h_OrderSubOrders(@order_id) ORDER BY suborder_id", conn);
            partsFunc.Parameters.Add(new SqlParameter("@order_id", orderId));
            DataTable parts = new DataTable();
            new SqlDataAdapter(partsFunc).Fill(parts);
            return parts;
        }

        protected void ordersRepeater_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem) return;
            DataRowView o = (DataRowView)e.Item.DataItem;

            int orderId = (int)o["order_id"];
            string status = (string)o["status"];
            string method = o["payment_method"] as string ?? "";
            decimal total = (decimal)o["total_amount"];
            decimal refunded = o["refunded_amount"] == DBNull.Value ? 0 : (decimal)o["refunded_amount"];

            DataTable parts = ReadParts(orderId);

            // Payment line
            ((Label)e.Item.FindControl("paymentLine")).Text = "Paid by " + method.ToLower()
                + ((decimal)o["discount_amount"] > 0 ? " &middot; voucher " + ((decimal)o["discount_amount"]).ToString("N2") + " off" : "")
                + (refunded > 0 ? " &middot; refunded " + refunded.ToString("N2") : "");

            // Can it be cancelled? Only if no part was picked up or delivered yet
            bool started = false;
            foreach (DataRow p in parts.Rows)
            {
                string ps = (string)p["status"];
                if (ps == "Picked Up" || ps == "Delivered") started = true;
            }
            Button cancel = (Button)e.Item.FindControl("cancelBtn");
            if (status != "Cancelled" && status != "Delivered" && !started)
            {
                cancel.Visible = true;
                cancel.OnClientClick = "return confirm('Cancel order #" + orderId + "? " + RefundText(method, total - refunded)
                                     + " This cannot be undone.');";
            }

            // Estimated arrival of the whole order = the latest part
            currentZoneAvg = zoneAvg.ContainsKey((string)o["zone_name"]) ? zoneAvg[(string)o["zone_name"]] : (decimal?)null;
            currentOrderDate = (DateTime)o["order_date"];

            Label eta = (Label)e.Item.FindControl("etaLine");
            if (status == "Cancelled")
            {
                eta.CssClass = "msg msg-error";
                eta.Text = "This order was cancelled." + (refunded > 0 && method != "Cash"
                         ? " " + refunded.ToString("N2") + " EGP was returned to your wallet." : "");
            }
            else if (status == "Delivered")
            {
                DateTime last = DateTime.MinValue;
                foreach (DataRow p in parts.Rows)
                    if (p["delivered_at"] != DBNull.Value && (DateTime)p["delivered_at"] > last) last = (DateTime)p["delivered_at"];
                eta.CssClass = "msg msg-success";
                eta.Text = "Delivered" + (last > DateTime.MinValue ? " on " + last.ToString("d MMM yyyy 'at' HH:mm") : "") + ".";
            }
            else
            {
                DateTime? latest = null;
                foreach (DataRow p in parts.Rows)
                {
                    DateTime? partEta = EstimatedArrival(p);
                    if (partEta != null && (latest == null || partEta > latest)) latest = partEta;
                }
                eta.CssClass = "msg msg-warning";
                eta.Text = latest == null ? "On the way." : "<b>On the way.</b> " + EtaText(latest.Value, "Everything should arrive");
            }

            Repeater partsRepeater = (Repeater)e.Item.FindControl("partsRepeater");
            partsRepeater.DataSource = parts;
            partsRepeater.DataBind();
        }

        protected void partsRepeater_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem) return;
            DataRowView p = (DataRowView)e.Item.DataItem;
            string status = (string)p["status"];

            // Where this part is in its journey
            string[] journey = { "Placed", "Assigned", "Picked Up", "Delivered" };
            string steps = "<div class=\"steps\">";
            if (status == "Cancelled")
                steps += "<span class=\"step cancelled\">Cancelled</span>";
            else
            {
                int at = Array.IndexOf(journey, status);
                for (int i = 0; i < journey.Length; i++)
                    steps += "<span class=\"step " + (i < at || status == "Delivered" ? "done" : i == at ? "current" : "") + "\">"
                           + (journey[i] == "Picked Up" ? "Picked up" : journey[i]) + "</span>";
            }
            ((Literal)e.Item.FindControl("steps")).Text = steps + "</div>";

            ((Label)e.Item.FindControl("riderLine")).Text = p["rider_name"] == DBNull.Value
                ? (status == "Cancelled" ? "" : "Waiting for a rider")
                : "Rider: " + HttpUtility.HtmlEncode((string)p["rider_name"]);

            // Estimated arrival of this part
            DateTime? eta = EstimatedArrival(p.Row);
            if (eta != null)
                ((Label)e.Item.FindControl("partEta")).Text = EtaText(eta.Value, "Arrives");

            // 3.6 e: feedback and rider rating for a delivered part
            if (status == "Delivered")
            {
                bool hasFeedback = Convert.ToBoolean(p["has_feedback"]);
                e.Item.FindControl("feedbackBtn").Visible = !hasFeedback;
                e.Item.FindControl("feedbackDone").Visible = hasFeedback;

                if (p["delivery_id"] != DBNull.Value)
                {
                    if (p["rider_rating"] == DBNull.Value)
                        e.Item.FindControl("ratePanel").Visible = true;
                    else
                    {
                        Label rated = (Label)e.Item.FindControl("ratedLine");
                        rated.Visible = true;
                        rated.Text = "You rated the rider " + p["rider_rating"] + " &#9733;";
                    }
                }
            }
        }

        // ---- Estimated arrival (3.6 c) ----
        // Not picked up yet: assigned time (or order time) + the business's expected delivery time.
        // Picked up: pick-up time + the zone's real average delivery time (or the expected time if the zone has no history).
        private DateTime? EstimatedArrival(DataRow p)
        {
            string status = (string)p["status"];
            int expected = Convert.ToInt32(p["expected_delivery_time"]);

            if (status == "Placed")
                return currentOrderDate.AddMinutes(expected);
            if (status == "Assigned")
                return (p["assigned_at"] == DBNull.Value ? currentOrderDate : (DateTime)p["assigned_at"]).AddMinutes(expected);
            if (status == "Picked Up")
            {
                double minutes = currentZoneAvg.HasValue ? (double)currentZoneAvg.Value : expected;
                return ((DateTime)p["picked_up_at"]).AddMinutes(minutes);
            }
            return null;   // Delivered or Cancelled
        }

        private static string EtaText(DateTime eta, string prefix)
        {
            string when = eta.Date == DateTime.Today ? eta.ToString("HH:mm") : eta.ToString("d MMM 'at' HH:mm");
            int minutes = (int)Math.Round((eta - DateTime.Now).TotalMinutes);
            if (minutes >= 0)
                return prefix + " around " + when + " (in about " + Math.Max(minutes, 1) + " min).";
            return "Expected by " + when + ", so it is running late. It should arrive very soon.";
        }

        private static string RefundText(string method, decimal amount)
        {
            if (method == "Cash")
                return "You pay cash on delivery, so nothing will be charged.";
            return amount.ToString("N2") + " EGP will be returned to your wallet.";
        }

        // ================= Order buttons: Cancel_Order, open the Reorder form =================

        protected void ordersRepeater_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName != "CancelOrder" && e.CommandName != "Reorder") return;
            int orderId = Convert.ToInt32(e.CommandArgument);

            // Cancel_Order and Reorder take only an order id: check the order is mine first
            DataRow order = MyOrder(orderId);
            if (order == null) return;

            if (e.CommandName == "Reorder")
            {
                OpenReorder(order);
                return;
            }

            string method = order["payment_method"] as string ?? "";
            decimal refund = (decimal)order["total_amount"]
                           - (order["refunded_amount"] == DBNull.Value ? 0 : (decimal)order["refunded_amount"]);

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand("Cancel_Order", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@order_id", orderId));

            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    ShowSuccess("Order #" + orderId + " was cancelled. "
                              + (method == "Cash" ? "You paid cash on delivery, so nothing was charged."
                                                  : refund.ToString("N2") + " EGP was returned to your wallet.")
                              + ((decimal)order["discount_amount"] > 0 ? " Your voucher can be used again." : ""));
                    break;
                case -1:
                    ShowError("This order does not exist anymore. The list has been refreshed.");
                    break;
                case -4:
                    ShowError("Order #" + orderId + " cannot be cancelled because it was already cancelled, "
                            + "or a part of it was already picked up.");
                    break;
                default:
                    ShowCodeError(rc);
                    return;
            }
            feedbackPanel.Visible = reorderPanel.Visible = false;
            BindOrders();
        }

        // ================= Reorder =================

        private void OpenReorder(DataRow order)
        {
            int orderId = (int)order["order_id"];
            string zone = (string)order["zone_name"];

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            // h_MyAddresses: the addresses I can reorder to (names, not ids)
            SqlCommand addressesFunc = new SqlCommand(
                "SELECT address_id, description, zone_name, is_active FROM dbo.h_MyAddresses(@customer_id) ORDER BY is_active DESC, address_id", conn);
            addressesFunc.Parameters.Add(new SqlParameter("@customer_id", CustomerId));
            DataTable addresses = new DataTable();
            try
            {
                new SqlDataAdapter(addressesFunc).Fill(addresses);
            }
            catch (SqlException)
            {
                ShowCodeError(int.MinValue);
                return;
            }

            reorderAddress.Items.Clear();
            foreach (DataRow a in addresses.Rows)
            {
                ListItem item = new ListItem((string)a["description"] + " (" + (string)a["zone_name"] + ")", a["address_id"].ToString());
                reorderAddress.Items.Add(item);
            }
            // Preselect an address in the order's zone
            foreach (DataRow a in addresses.Rows)
                if ((string)a["zone_name"] == zone) { reorderAddress.SelectedValue = a["address_id"].ToString(); break; }

            ViewState["reorderId"] = orderId;
            ViewState["reorderZone"] = zone;
            reorderTitle.Text = "Reorder order #" + orderId + " (" + HttpUtility.HtmlEncode(zone) + ")";
            reorderPanel.Visible = true;
            feedbackPanel.Visible = false;
            msg.Text = "";
        }

        protected void reorder_Click(object sender, EventArgs e)
        {
            if (ViewState["reorderId"] == null) return;
            if (reorderAddress.SelectedValue == "")
            {
                ShowError("Choose the address to deliver to. <a href=\"CustomerAddresses.aspx\">Add an address</a> if you have none.");
                return;
            }
            int orderId = (int)ViewState["reorderId"];
            if (MyOrder(orderId) == null) return;

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand("Reorder", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@order_id", orderId));
            proc.Parameters.Add(new SqlParameter("@address_id", Convert.ToInt32(reorderAddress.SelectedValue)));

            string address = HttpUtility.HtmlEncode(reorderAddress.SelectedItem.Text);
            string zone = HttpUtility.HtmlEncode((string)ViewState["reorderZone"]);
            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    ShowSuccess("A new cart with the products of order #" + orderId + " was created for " + address
                              + ", which is now your active address. <a href=\"CustomerCart.aspx\">Go to my cart</a> to check out.");
                    reorderPanel.Visible = false;
                    break;
                case -1:
                    ShowError("This order does not exist anymore.");
                    break;
                case -2:
                    ShowError("You already have a cart for " + address + ". Check it out or empty it first, or choose another address.");
                    return;
                case -3:
                    ShowError("You cannot reorder: the address is not yours, or your account is blacklisted. Contact support if you think this is wrong.");
                    return;
                case -5:
                    ShowError("This address is not in " + zone + ", where the businesses of this order deliver. Choose an address in " + zone + ".");
                    return;
                case -9:
                    ShowError("None of the products of order #" + orderId + " can be ordered now (they are not available, or the business "
                            + "is not active). Browse for something else.");
                    return;
                default:
                    ShowCodeError(rc);
                    return;
            }
            BindOrders();
        }

        // ================= Part buttons: Submit_Feedback form, Rate_Rider =================

        protected void partsRepeater_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName != "Feedback" && e.CommandName != "RateRider") return;
            int subId = Convert.ToInt32(e.CommandArgument);

            // Submit_Feedback and Rate_Rider take only the part id: check the part is in one of my orders first
            DataRow part = MyPart(subId);
            if (part == null) return;

            if (e.CommandName == "Feedback")
            {
                ViewState["feedbackSub"] = subId;
                feedbackTitle.Text = "Feedback for " + HttpUtility.HtmlEncode((string)part["business_name"])
                                   + " (order #" + part["order_id"] + ")";
                fbHeadline.Text = fbDescription.Text = "";
                fbRating.SelectedIndex = 0;
                feedbackPanel.Visible = true;
                reorderPanel.Visible = false;
                msg.Text = "";
                return;
            }

            string rating = ((DropDownList)e.Item.FindControl("riderRating")).SelectedValue;
            if (rating == "")
            {
                ShowError("Choose from 1 to 5 stars for the rider, then click Rate.");
                return;
            }

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand("Rate_Rider", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@suborder_id", subId));
            proc.Parameters.Add(new SqlParameter("@rider_rating", Convert.ToInt32(rating)));

            string rider = HttpUtility.HtmlEncode(part["rider_name"] as string ?? "the rider");
            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    ShowSuccess("Thank you! You rated " + rider + " " + rating + " &#9733;.");
                    break;
                case -1:
                    ShowError("Choose from 1 to 5 stars for the rider.");
                    return;
                case -2:
                    ShowError("You already rated " + rider + " for this delivery.");
                    break;
                case -4:
                    ShowError("You can rate the rider only after this part was delivered.");
                    break;
                default:
                    ShowCodeError(rc);
                    return;
            }
            BindOrders();
        }

        protected void feedback_Click(object sender, EventArgs e)
        {
            if (ViewState["feedbackSub"] == null) return;
            int subId = (int)ViewState["feedbackSub"];
            string headline = fbHeadline.Text.Trim();
            string description = fbDescription.Text.Trim();

            if (headline == "" || fbRating.SelectedValue == "")
            {
                ShowError("Please write a headline and choose a rating from 1 to 5.");
                return;
            }
            if (description.Length > 500)
            {
                ShowError("The details are too long. Keep them under 500 characters.");
                return;
            }
            DataRow part = MyPart(subId);
            if (part == null) return;

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand("Submit_Feedback", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@suborder_id", subId));
            proc.Parameters.Add(new SqlParameter("@headline", headline));
            proc.Parameters.Add(new SqlParameter("@description", description == "" ? (object)DBNull.Value : description));
            proc.Parameters.Add(new SqlParameter("@rating", Convert.ToInt32(fbRating.SelectedValue)));

            string business = HttpUtility.HtmlEncode((string)part["business_name"]);
            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    ShowSuccess("Thank you! Your feedback for " + business + " was sent.");
                    feedbackPanel.Visible = false;
                    break;
                case -1:
                    ShowError("Please write a headline and choose a rating from 1 to 5.");
                    return;
                case -2:
                    ShowError("You already left feedback for this part of the order.");
                    feedbackPanel.Visible = false;
                    break;
                case -4:
                    ShowError("You can leave feedback only after this part was delivered.");
                    feedbackPanel.Visible = false;
                    break;
                default:
                    ShowCodeError(rc);
                    return;
            }
            BindOrders();
        }

        protected void closePanels_Click(object sender, EventArgs e)
        {
            feedbackPanel.Visible = reorderPanel.Visible = false;
            msg.Text = "";
        }

        // ================= Ownership checks =================

        // One of my orders (My_Order_History), or null with a message
        private DataRow MyOrder(int orderId)
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand historyFunc = new SqlCommand(
                "SELECT * FROM dbo.My_Order_History(@customer_id) WHERE order_id = @order_id", conn);
            historyFunc.Parameters.Add(new SqlParameter("@customer_id", CustomerId));
            historyFunc.Parameters.Add(new SqlParameter("@order_id", orderId));
            DataTable rows = new DataTable();
            try
            {
                new SqlDataAdapter(historyFunc).Fill(rows);
            }
            catch (SqlException)
            {
                ShowCodeError(int.MinValue);
                return null;
            }
            if (rows.Rows.Count == 0)
            {
                ShowError("This order is not one of your orders.");
                BindOrders();
                return null;
            }
            return rows.Rows[0];
        }

        // A part of one of my orders (My_Order_History + h_OrderSubOrders), or null with a message
        private DataRow MyPart(int subId)
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand partCmd = new SqlCommand(
                "SELECT o.order_id, s.* FROM dbo.My_Order_History(@customer_id) o "
              + "CROSS APPLY dbo.h_OrderSubOrders(o.order_id) s WHERE s.suborder_id = @suborder_id", conn);
            partCmd.Parameters.Add(new SqlParameter("@customer_id", CustomerId));
            partCmd.Parameters.Add(new SqlParameter("@suborder_id", subId));
            DataTable rows = new DataTable();
            try
            {
                new SqlDataAdapter(partCmd).Fill(rows);
            }
            catch (SqlException)
            {
                ShowCodeError(int.MinValue);
                return null;
            }
            if (rows.Rows.Count == 0)
            {
                ShowError("This part is not in one of your orders.");
                BindOrders();
                return null;
            }
            return rows.Rows[0];
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
