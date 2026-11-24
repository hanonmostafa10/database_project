using System;
using System.Data;
using System.Data.SqlClient;
using System.Web;
using System.Web.Configuration;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebApplication1
{
    // 3.4 e (switch my availability) and 3.4 f (my active deliveries, mark Picked Up / Delivered)
    // The session check is in Rider.master (Page_Init), which runs before this page.
    public partial class RiderHome : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
                ShowAll();
        }

        private void ShowAll()
        {
            try
            {
                ShowProfile();
                ShowDeliveries();
            }
            catch (SqlException)
            {
                ShowError("We could not load your deliveries right now. Please refresh the page in a moment.");
            }
        }

        // ================= 3.4 e: h_RiderProfile + availability =================

        private void ShowProfile()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand profileFunc = new SqlCommand(
                "SELECT rider_name, zone_name, vehicle_type, plate_no, is_available FROM dbo.h_RiderProfile(@rider_id)", conn);
            profileFunc.Parameters.Add(new SqlParameter("@rider_id", (int)Session["user"]));

            DataTable rows = new DataTable();
            new SqlDataAdapter(profileFunc).Fill(rows);
            if (rows.Rows.Count == 0) return;
            DataRow r = rows.Rows[0];

            bool available = (bool)r["is_available"];
            ViewState["available"] = available;

            riderName.Text = HttpUtility.HtmlEncode((string)r["rider_name"]);
            riderInfo.Text = "Zone: " + HttpUtility.HtmlEncode((string)r["zone_name"]) + " &middot; "
                           + HttpUtility.HtmlEncode((string)r["vehicle_type"]) + " " + HttpUtility.HtmlEncode((string)r["plate_no"]);
            availabilityBadge.Text = available ? "Available" : "Unavailable";
            availabilityBadge.CssClass = available ? "status status-Active" : "status status-Rejected";
            toggleBtn.Text = available ? "Go unavailable" : "Go available";
            toggleBtn.CssClass = available ? "btn btn-secondary" : "btn";
        }

        protected void toggle_Click(object sender, EventArgs e)
        {
            bool makeAvailable = !(ViewState["available"] != null && (bool)ViewState["available"]);

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand("Set_Rider_Availability", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@rider_id", (int)Session["user"]));
            proc.Parameters.Add(new SqlParameter("@is_available", makeAvailable));

            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    ShowSuccess(makeAvailable
                        ? "You are available. New orders in your zone can now be assigned to you."
                        : "You are unavailable. You will not get new deliveries; finish the ones you already have.");
                    break;
                case -1:
                    ShowError("Your availability could not be changed. Refresh the page and try again.");
                    break;
                case -3:
                    ShowError("Only a rider can change their availability.");
                    break;
                default:
                    ShowCodeError(rc);
                    return;
            }
            ShowAll();
        }

        // ================= 3.4 f: My_Active_Deliveries =================

        private DataTable ReadActiveDeliveries()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            // Picked Up first (deliver it now), then the oldest assigned one
            SqlCommand activeFunc = new SqlCommand(
                "SELECT * FROM dbo.My_Active_Deliveries(@rider_id) "
              + "ORDER BY CASE WHEN status = 'Picked Up' THEN 0 ELSE 1 END, assigned_at", conn);
            activeFunc.Parameters.Add(new SqlParameter("@rider_id", (int)Session["user"]));

            DataTable rows = new DataTable();
            new SqlDataAdapter(activeFunc).Fill(rows);
            return rows;
        }

        private void ShowDeliveries()
        {
            DataTable rows = ReadActiveDeliveries();
            deliveries.DataSource = rows;
            deliveries.DataBind();

            // Answer "what do I do next?" in one sentence
            if (rows.Rows.Count == 0)
            {
                bool available = ViewState["available"] != null && (bool)ViewState["available"];
                SetMsg(nextStep, "msg-success", available
                    ? "You have no active deliveries. Stay available; new orders in your zone will appear here."
                    : "You have no active deliveries. Switch to available to get new orders.");
                return;
            }

            DataRow first = rows.Rows[0];
            string order = "order #" + first["order_id"];
            string business = HttpUtility.HtmlEncode((string)first["business_name"]);
            if ((string)first["status"] == "Picked Up")
                SetMsg(nextStep, "msg-warning", "<b>Next: deliver " + order + "</b> from " + business + " to "
                     + HttpUtility.HtmlEncode((string)first["customer_name"]) + " at "
                     + HttpUtility.HtmlEncode((string)first["address_description"]) + ", then mark it as delivered.");
            else
                SetMsg(nextStep, "msg-warning", "<b>Next: go to " + business + "</b> and pick up " + order + ", then mark it as picked up.");

            if (rows.Rows.Count > 1)
                nextStep.Text += " You have " + rows.Rows.Count + " active deliveries in total.";
        }

        protected void deliveries_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem) return;

            string status = (string)DataBinder.Eval(e.Item.DataItem, "status");
            bool pickedUp = status == "Picked Up";

            // Where the delivery is in its journey: Assigned -> Picked Up -> Delivered
            ((Literal)e.Item.FindControl("steps")).Text =
                "<div class=\"steps\">"
              + "<span class=\"step done\">Assigned</span>"
              + "<span class=\"step " + (pickedUp ? "done" : "current") + "\">Picked up</span>"
              + "<span class=\"step " + (pickedUp ? "current" : "") + "\">Delivered</span>"
              + "</div>";

            // The one action that comes next
            Button action = (Button)e.Item.FindControl("actionBtn");
            if (pickedUp)
            {
                action.Text = "Mark as delivered";
                action.CommandName = "Deliver";
                action.OnClientClick = "return confirm('Mark order #" + DataBinder.Eval(e.Item.DataItem, "order_id")
                    + " as delivered to " + HttpUtility.JavaScriptStringEncode((string)DataBinder.Eval(e.Item.DataItem, "customer_name"))
                    + "? Do this only after you hand it over.');";
            }
            else
            {
                action.Text = "Mark as picked up";
                action.CommandName = "PickUp";
            }
        }

        protected void deliveries_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName != "PickUp" && e.CommandName != "Deliver") return;
            int deliveryId = Convert.ToInt32(e.CommandArgument);
            bool pickUp = e.CommandName == "PickUp";

            // Mark_Picked_Up / Mark_Delivered do not check the rider, so check this delivery is mine first
            DataRow mine = null;
            try
            {
                foreach (DataRow row in ReadActiveDeliveries().Rows)
                    if ((int)row["delivery_id"] == deliveryId) mine = row;
            }
            catch (SqlException)
            {
                ShowCodeError(int.MinValue);
                return;
            }
            if (mine == null)
            {
                ShowError("This delivery is not one of your active deliveries anymore (it may have been cancelled). The list has been refreshed.");
                ShowAll();
                return;
            }

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand(pickUp ? "Mark_Picked_Up" : "Mark_Delivered", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@delivery_id", deliveryId));

            string order = "Order #" + mine["order_id"];
            string customer = HttpUtility.HtmlEncode((string)mine["customer_name"]);

            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    if (pickUp)
                        ShowSuccess(order + " was picked up from " + HttpUtility.HtmlEncode((string)mine["business_name"])
                                  + ". Now deliver it to " + customer + ".");
                    else
                        ShowSuccess(order + " was delivered to " + customer + ". Well done!");
                    break;
                case -1:
                    ShowError("This delivery does not exist anymore. The list has been refreshed.");
                    break;
                case -4:
                    ShowError(pickUp
                        ? order + " was already picked up or was cancelled. The list has been refreshed."
                        : order + " can be marked as delivered only after it was picked up. Mark it as picked up first.");
                    break;
                default:
                    ShowCodeError(rc);
                    return;
            }
            ShowAll();
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

        private static void SetMsg(Label label, string kind, string text)
        {
            label.CssClass = "msg " + kind;
            label.Text = text;
        }

        private void ShowSuccess(string text) { SetMsg(msg, "msg-success", text); }
        private void ShowError(string text) { SetMsg(msg, "msg-error", text); }
    }
}
