using System;
using System.Data;
using System.Data.SqlClient;
using System.Web;
using System.Web.Configuration;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebApplication1
{
    // 3.5 b: add, edit or delete an address and choose my active address
    // The session check is in Customer.master (Page_Init), which runs before this page.
    public partial class CustomerAddresses : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadZones();
                BindAddresses();
            }
        }

        // ================= Loading =================

        // h_ZoneList: the zones to choose from
        private void LoadZones()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand zonesView = new SqlCommand("SELECT zone_id, zone_name FROM h_ZoneList ORDER BY zone_name", conn);
            DataTable rows = new DataTable();
            try
            {
                new SqlDataAdapter(zonesView).Fill(rows);
            }
            catch (SqlException)
            {
                ShowError("We could not load the zones right now. Please refresh the page in a moment.");
                return;
            }

            aZone.Items.Clear();
            aZone.Items.Add(new ListItem("-- Choose a zone --", ""));
            foreach (DataRow row in rows.Rows)
                aZone.Items.Add(new ListItem((string)row["zone_name"], row["zone_id"].ToString()));
        }

        // h_MyAddresses
        private void BindAddresses()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand addressesFunc = new SqlCommand(
                "SELECT address_id, description, zone_id, zone_name, is_active FROM dbo.h_MyAddresses(@customer_id) "
              + "ORDER BY is_active DESC, address_id", conn);
            addressesFunc.Parameters.Add(new SqlParameter("@customer_id", (int)Session["user"]));

            DataTable rows = new DataTable();
            try
            {
                new SqlDataAdapter(addressesFunc).Fill(rows);
            }
            catch (SqlException)
            {
                ShowError("We could not load your addresses right now. Please refresh the page in a moment.");
                return;
            }
            addressesGrid.DataSource = rows;
            addressesGrid.DataBind();
        }

        protected void addressesGrid_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType != DataControlRowType.DataRow) return;

            bool active = (bool)DataBinder.Eval(e.Row.DataItem, "is_active");
            e.Row.FindControl("activeBadge").Visible = active;
            e.Row.FindControl("activateBtn").Visible = !active;

            // Deleting cannot be undone: say what will happen first
            string description = (string)DataBinder.Eval(e.Row.DataItem, "description");
            ((Button)e.Row.FindControl("deleteBtn")).OnClientClick =
                "return confirm('Delete the address \"" + HttpUtility.JavaScriptStringEncode(description) + "\"? This cannot be undone."
              + (active ? " Your first remaining address will become your active address." : "") + "');";
        }

        // ================= Buttons =================

        protected void add_Click(object sender, EventArgs e)
        {
            ViewState["editId"] = null;
            formTitle.Text = "Add an address";
            formNote.Text = "The new address becomes your active address.";
            aDescription.Text = "";
            aZone.SelectedIndex = 0;
            addressForm.Visible = true;
            msg.Text = "";
        }

        protected void cancel_Click(object sender, EventArgs e)
        {
            addressForm.Visible = false;
            msg.Text = "";
        }

        protected void addressesGrid_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName != "Activate" && e.CommandName != "EditAddress" && e.CommandName != "DeleteAddress") return;

            DataKey key = addressesGrid.DataKeys[Convert.ToInt32(e.CommandArgument)];
            int addressId = (int)key["address_id"];
            string description = (string)key["description"];
            msg.Text = "";

            if (e.CommandName == "EditAddress")
            {
                ViewState["editId"] = addressId;
                formTitle.Text = "Edit address";
                formNote.Text = "";
                aDescription.Text = description;
                aZone.SelectedValue = key["zone_id"].ToString();
                addressForm.Visible = true;
            }
            else if (e.CommandName == "Activate")
            {
                ChangeActive(addressId, description);
            }
            else
            {
                Delete(addressId, description, (bool)key["is_active"]);
            }
        }

        // ================= Add_Customer_Address / Update_Delete_Customer_Address (Update) =================

        protected void save_Click(object sender, EventArgs e)
        {
            string description = aDescription.Text.Trim();
            if (description == "" || aZone.SelectedValue == "")
            {
                ShowError("Please write the address and choose its zone.");
                return;
            }
            bool editing = ViewState["editId"] != null;

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc;
            if (editing)
            {
                proc = new SqlCommand("Update_Delete_Customer_Address", conn);
                proc.CommandType = CommandType.StoredProcedure;
                proc.Parameters.Add(new SqlParameter("@customer_id", (int)Session["user"]));
                proc.Parameters.Add(new SqlParameter("@address_id", (int)ViewState["editId"]));
                proc.Parameters.Add(new SqlParameter("@description", description));
                proc.Parameters.Add(new SqlParameter("@zone_id", Convert.ToInt32(aZone.SelectedValue)));
                proc.Parameters.Add(new SqlParameter("@action", "Update"));
            }
            else
            {
                proc = new SqlCommand("Add_Customer_Address", conn);
                proc.CommandType = CommandType.StoredProcedure;
                proc.Parameters.Add(new SqlParameter("@customer_id", (int)Session["user"]));
                proc.Parameters.Add(new SqlParameter("@description", description));
                proc.Parameters.Add(new SqlParameter("@zone_id", Convert.ToInt32(aZone.SelectedValue)));
            }

            string safe = HttpUtility.HtmlEncode(description);
            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    ShowSuccess(editing ? "The address \"" + safe + "\" was saved."
                                        : "The address \"" + safe + "\" was added and is now your active address.");
                    addressForm.Visible = false;
                    break;
                case -1:
                    ShowError("Please write the address and choose its zone.");
                    return;
                case -3:
                    ShowError("This address is not one of your addresses.");
                    break;
                case -4:
                    ShowError("This address has an order on the way, so it cannot be changed until the order arrives. "
                            + "Add a new address instead.");
                    return;
                default:
                    ShowCodeError(rc);
                    return;
            }
            BindAddresses();
        }

        // ================= Update_Delete_Customer_Address (Delete) =================

        private void Delete(int addressId, string description, bool wasActive)
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand("Update_Delete_Customer_Address", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@customer_id", (int)Session["user"]));
            proc.Parameters.Add(new SqlParameter("@address_id", addressId));
            proc.Parameters.Add(new SqlParameter("@description", DBNull.Value));
            proc.Parameters.Add(new SqlParameter("@zone_id", DBNull.Value));
            proc.Parameters.Add(new SqlParameter("@action", "Delete"));

            string safe = HttpUtility.HtmlEncode(description);
            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    ShowSuccess("The address \"" + safe + "\" was deleted."
                              + (wasActive ? " Your first remaining address is now your active address." : ""));
                    break;
                case -1:
                    ShowError("This address does not exist anymore. The list has been refreshed.");
                    break;
                case -3:
                    ShowError("This address is not one of your addresses.");
                    break;
                case -4:
                    ShowError("The address \"" + safe + "\" was already used for a cart or an order, so it cannot be deleted. "
                            + "You can edit it, or choose another active address.");
                    break;
                default:
                    ShowCodeError(rc);
                    return;
            }
            addressForm.Visible = false;
            BindAddresses();
        }

        // ================= Change_Active_Address =================

        private void ChangeActive(int addressId, string description)
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand("Change_Active_Address", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@customer_id", (int)Session["user"]));
            proc.Parameters.Add(new SqlParameter("@new_address_id", addressId));

            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    ShowSuccess("\"" + HttpUtility.HtmlEncode(description) + "\" is now your active address. "
                              + "You now see the businesses of its zone, and your cart is the one of this address.");
                    break;
                case -3:
                    ShowError("This address is not one of your addresses. The list has been refreshed.");
                    break;
                default:
                    ShowCodeError(rc);
                    return;
            }
            addressForm.Visible = false;
            BindAddresses();
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
