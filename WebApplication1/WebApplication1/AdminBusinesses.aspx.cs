using System;
using System.Data;
using System.Data.SqlClient;
using System.Web;
using System.Web.Configuration;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebApplication1
{
    // 3.2 b (approve / reject pending businesses) and 3.2 c (suspend, reinstate, browse all profiles)
    // The session check is in Admin.master (Page_Init), which runs before this page.
    public partial class AdminBusinesses : System.Web.UI.Page
    {
        private bool IsSuperAdmin
        {
            get { return (string)Session["role"] == "Super Admin"; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
                BindAll();
        }

        // ================= Loading the lists =================

        private void BindAll()
        {
            try
            {
                BindPending();
                BindAllBusinesses();
                BindSuspended();
            }
            catch (SqlException)
            {
                ShowError("We could not load the businesses right now. Please refresh the page in a moment.");
            }
        }

        // PendingBusinessApprovals: a Zone Admin only sees the businesses of their own zone
        private void BindPending()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand pendingView = new SqlCommand(
                "SELECT business_id, business_name, business_type, zone_name, partner_name "
              + "FROM PendingBusinessApprovals WHERE (@zone IS NULL OR zone_name = @zone) ORDER BY business_id", conn);
            pendingView.Parameters.Add(new SqlParameter("@zone",
                IsSuperAdmin || Session["zoneName"] == null ? (object)DBNull.Value : Session["zoneName"]));

            DataTable rows = new DataTable();
            new SqlDataAdapter(pendingView).Fill(rows);
            pendingGrid.DataSource = rows;
            pendingGrid.DataBind();

            pendingNote.Text = IsSuperAdmin ? "" : "You see the businesses of your zone ("
                             + HttpUtility.HtmlEncode((string)Session["zoneName"]) + ").";
        }

        // allBusinessProfiles filtered by status and type
        private void BindAllBusinesses()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand profilesView = new SqlCommand(
                "SELECT business_id, business_name, business_type, zone_name, partner_name, status, "
              + "CONVERT(VARCHAR(5), opening_hour, 108) + ' - ' + CONVERT(VARCHAR(5), closing_hour, 108) AS hours "
              + "FROM allBusinessProfiles "
              + "WHERE (@status = '' OR status = @status) AND (@type = '' OR business_type = @type) "
              + "ORDER BY business_name", conn);
            profilesView.Parameters.Add(new SqlParameter("@status", statusFilter.SelectedValue));
            profilesView.Parameters.Add(new SqlParameter("@type", typeFilter.SelectedValue));

            DataTable rows = new DataTable();
            new SqlDataAdapter(profilesView).Fill(rows);
            allGrid.DataSource = rows;
            allGrid.DataBind();
        }

        // h_SuspendedBusinesses: suspended businesses with their reasons
        private void BindSuspended()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand suspendedView = new SqlCommand(
                "SELECT business_id, business_name, zone_name, suspension_reason FROM h_SuspendedBusinesses ORDER BY business_name", conn);

            DataTable rows = new DataTable();
            new SqlDataAdapter(suspendedView).Fill(rows);
            suspendedGrid.DataSource = rows;
            suspendedGrid.DataBind();

            // Reinstating is a Super Admin feature: hidden for a Zone Admin
            suspendedGrid.Columns[3].Visible = IsSuperAdmin;
            reinstateNote.Text = IsSuperAdmin ? "" : "Only a Super Admin can reinstate a suspended business.";
        }

        protected void filter_Changed(object sender, EventArgs e)
        {
            suspendPanel.Visible = false;
            try { BindAllBusinesses(); }
            catch (SqlException) { ShowError("We could not load the businesses right now. Please try again in a moment."); }
        }

        // ================= Row buttons =================

        protected void pendingGrid_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType != DataControlRowType.DataRow) return;
            string name = (string)DataBinder.Eval(e.Row.DataItem, "business_name");
            Button reject = (Button)e.Row.FindControl("rejectBtn");
            reject.OnClientClick = "return confirm('Reject " + HttpUtility.JavaScriptStringEncode(name)
                                 + "? The owner will see that the business was rejected and will have to register it again.');";
        }

        protected void allGrid_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType != DataControlRowType.DataRow) return;
            string status = (string)DataBinder.Eval(e.Row.DataItem, "status");
            string zone = (string)DataBinder.Eval(e.Row.DataItem, "zone_name");

            // Only an Active business can be suspended, and a Zone Admin only manages their own zone
            bool canManage = IsSuperAdmin || zone == (string)Session["zoneName"];
            e.Row.FindControl("suspendBtn").Visible = status == "Active" && canManage;
        }

        protected void pendingGrid_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName != "Approve" && e.CommandName != "Reject") return;

            int index = Convert.ToInt32(e.CommandArgument);
            int businessId = (int)pendingGrid.DataKeys[index]["business_id"];
            string name = HttpUtility.HtmlEncode((string)pendingGrid.DataKeys[index]["business_name"]);
            bool approve = e.CommandName == "Approve";

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand(approve ? "Approve_Business" : "Reject_Business", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@business_id", businessId));
            proc.Parameters.Add(new SqlParameter("@admin_id", (int)Session["user"]));

            int code = RunProcedure(proc);
            switch (code)
            {
                case 0:
                    if (approve)
                        ShowSuccess(name + " was approved. It is now active and customers can order from it.");
                    else
                        ShowSuccess(name + " was rejected. The owner can correct it and register the business again.");
                    break;
                case -1:
                    ShowError("This business does not exist anymore. The list has been refreshed.");
                    break;
                case -3:
                    ShowError("You can only " + (approve ? "approve" : "reject") + " businesses in your own zone. "
                            + "Ask the admin of that zone or a Super Admin.");
                    break;
                case -4:
                    ShowError(name + " is no longer waiting for approval (another admin may have handled it). "
                            + "The list has been refreshed.");
                    break;
                default:
                    ShowCodeError(code);
                    break;
            }
            BindAll();
        }

        protected void allGrid_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName != "StartSuspend") return;

            // Open the suspend form for this business (the reason is asked before suspending)
            int index = Convert.ToInt32(e.CommandArgument);
            ViewState["suspendId"] = (int)allGrid.DataKeys[index]["business_id"];
            ViewState["suspendName"] = (string)allGrid.DataKeys[index]["business_name"];

            suspendName.Text = HttpUtility.HtmlEncode((string)ViewState["suspendName"]);
            suspendReason.Text = "";
            suspendPanel.Visible = true;
            suspendConfirmBtn.OnClientClick = "return confirm('Suspend "
                + HttpUtility.JavaScriptStringEncode((string)ViewState["suspendName"])
                + "? All its products will be hidden, and its orders that were not picked up yet will be cancelled and refunded.');";
            msg.Text = "";
        }

        protected void suspendCancel_Click(object sender, EventArgs e)
        {
            suspendPanel.Visible = false;
            msg.Text = "";
        }

        protected void suspend_Click(object sender, EventArgs e)
        {
            if (ViewState["suspendId"] == null) return;
            string name = HttpUtility.HtmlEncode((string)ViewState["suspendName"]);
            string reason = suspendReason.Text.Trim();

            // Check the input before calling the database
            if (reason == "")
            {
                ShowError("Please write the reason for suspending " + name + ". The owner will see it.");
                return;
            }
            if (reason.Length > 255)
            {
                ShowError("The reason is too long. Keep it under 255 characters.");
                return;
            }

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand("Suspend_Business", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@business_id", (int)ViewState["suspendId"]));
            proc.Parameters.Add(new SqlParameter("@admin_id", (int)Session["user"]));
            proc.Parameters.Add(new SqlParameter("@reason", reason));

            int code = RunProcedure(proc);
            switch (code)
            {
                case 0:
                    ShowSuccess(name + " was suspended. Its products are hidden, and its orders that were not "
                              + "picked up yet were cancelled and refunded.");
                    suspendPanel.Visible = false;
                    break;
                case -1:
                    ShowError("Please write the reason for suspending " + name + ".");
                    break;
                case -3:
                    ShowError("You can only suspend businesses in your own zone. Ask the admin of that zone or a Super Admin.");
                    suspendPanel.Visible = false;
                    break;
                case -4:
                    ShowError("Only an active business can be suspended, and " + name + " is not active anymore. "
                            + "The list has been refreshed.");
                    suspendPanel.Visible = false;
                    break;
                default:
                    ShowCodeError(code);
                    break;
            }
            if (code != -1) BindAll();
        }

        protected void suspendedGrid_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName != "Reinstate") return;

            int index = Convert.ToInt32(e.CommandArgument);
            int businessId = (int)suspendedGrid.DataKeys[index]["business_id"];
            string name = HttpUtility.HtmlEncode((string)suspendedGrid.DataKeys[index]["business_name"]);

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand("Reinstate_Business", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@business_id", businessId));
            proc.Parameters.Add(new SqlParameter("@super_admin_id", (int)Session["user"]));

            int code = RunProcedure(proc);
            switch (code)
            {
                case 0:
                    ShowSuccess(name + " is active again. Its owner can now make its products available again.");
                    break;
                case -1:
                    ShowError("This business does not exist anymore. The list has been refreshed.");
                    break;
                case -3:
                    ShowError("Only a Super Admin can reinstate a suspended business.");
                    break;
                case -4:
                    ShowError(name + " is not suspended anymore. The list has been refreshed.");
                    break;
                default:
                    ShowCodeError(code);
                    break;
            }
            BindAll();
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
