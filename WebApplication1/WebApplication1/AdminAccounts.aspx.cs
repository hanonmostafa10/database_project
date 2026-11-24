using System;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Web;
using System.Web.Configuration;
using System.Web.UI.WebControls;

namespace WebApplication1
{
    // 3.2 d: create a new admin and assign or move a Zone Admin to a zone (Super Admin only)
    // The session check is in Admin.master (Page_Init), which runs before this page.
    public partial class AdminAccounts : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // Super Admin only: a Zone Admin does not get this page (the menu link is also hidden)
            if ((string)Session["role"] != "Super Admin")
            {
                superAdminPanel.Visible = false;
                ShowError("Only a Super Admin can create admins or assign zones. Go back to the dashboard.");
                return;
            }

            if (!IsPostBack)
                BindAll();
        }

        private void BindAll()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            // h_AdminList: all admins (also the Zone Admins for Assign_Admin_Zone)
            SqlCommand adminsView = new SqlCommand(
                "SELECT admin_id, admin_name, username, role, zone_name FROM h_AdminList ORDER BY role DESC, admin_name", conn);
            // h_ZoneList: the zones to choose from
            SqlCommand zonesView = new SqlCommand(
                "SELECT zone_id, zone_name FROM h_ZoneList ORDER BY zone_name", conn);

            DataTable admins = new DataTable();
            DataTable zones = new DataTable();
            try
            {
                new SqlDataAdapter(adminsView).Fill(admins);
                new SqlDataAdapter(zonesView).Fill(zones);
            }
            catch (SqlException)
            {
                ShowError("We could not load the admins right now. Please refresh the page in a moment.");
                return;
            }

            adminsGrid.DataSource = admins;
            adminsGrid.DataBind();

            assignAdmin.Items.Clear();
            assignAdmin.Items.Add(new ListItem("-- Choose a Zone Admin --", ""));
            foreach (DataRow row in admins.Rows)
            {
                if ((string)row["role"] != "Zone Admin") continue;
                string text = (string)row["admin_name"] + " (" + (string)row["username"] + ")";
                text += row["zone_name"] == DBNull.Value ? " - no zone yet" : " - now " + (string)row["zone_name"];
                assignAdmin.Items.Add(new ListItem(text, row["admin_id"].ToString()));
            }

            assignZone.Items.Clear();
            newZone.Items.Clear();
            assignZone.Items.Add(new ListItem("-- Choose a zone --", ""));
            newZone.Items.Add(new ListItem("-- Choose a zone --", ""));
            foreach (DataRow row in zones.Rows)
            {
                assignZone.Items.Add(new ListItem((string)row["zone_name"], row["zone_id"].ToString()));
                newZone.Items.Add(new ListItem((string)row["zone_name"], row["zone_id"].ToString()));
            }
        }

        // A Super Admin has no zone: show the zone list only for a Zone Admin
        protected void newRole_Changed(object sender, EventArgs e)
        {
            newZonePanel.Visible = newRole.SelectedValue == "Zone Admin";
            msg.Text = "";
        }

        // ================= Assign_Admin_Zone =================

        protected void assign_Click(object sender, EventArgs e)
        {
            if (assignAdmin.SelectedValue == "" || assignZone.SelectedValue == "")
            {
                ShowError("Please choose a Zone Admin and the zone they will manage.");
                return;
            }

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand("Assign_Admin_Zone", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@admin_id", Convert.ToInt32(assignAdmin.SelectedValue)));
            proc.Parameters.Add(new SqlParameter("@zone_id", Convert.ToInt32(assignZone.SelectedValue)));
            proc.Parameters.Add(new SqlParameter("@super_admin_id", (int)Session["user"]));

            string adminName = assignAdmin.SelectedItem.Text;
            adminName = HttpUtility.HtmlEncode(adminName.Substring(0, adminName.IndexOf(" (")));
            string zoneName = HttpUtility.HtmlEncode(assignZone.SelectedItem.Text);

            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    ShowSuccess(adminName + " now manages the zone " + zoneName + ".");
                    break;
                case -1:
                    ShowError("This admin is not a Zone Admin anymore, or the zone does not exist. The lists have been refreshed.");
                    break;
                case -3:
                    ShowError("Only a Super Admin can assign zones.");
                    break;
                default:
                    ShowCodeError(rc);
                    return;
            }
            BindAll();
        }

        // ================= Create_Admin =================

        protected void create_Click(object sender, EventArgs e)
        {
            string role = newRole.SelectedValue;
            string first = firstName.Text.Trim();
            string middle = middleName.Text.Trim();
            string last = lastName.Text.Trim();
            string user = newUsername.Text.Trim();
            string pass = newPassword.Text;
            string mail = email.Text.Trim();
            string phoneNo = phone.Text.Trim();

            // Check the input before calling the database
            if (role == "Zone Admin" && newZone.SelectedValue == "")
            {
                ShowError("A Zone Admin manages one zone. Please choose the zone.");
                return;
            }
            if (first == "" || last == "" || user == "" || pass == "" || mail == "")
            {
                ShowError("Please fill in the first name, last name, username, password and email.");
                return;
            }
            if (pass != confirmPassword.Text)
            {
                ShowError("The two passwords do not match. Type the same password in both boxes.");
                return;
            }
            if (!mail.Contains("@") || !mail.Contains("."))
            {
                ShowError("The email address does not look right. Enter it like name@example.com.");
                return;
            }
            if (phoneNo != "" && (phoneNo.Length != 11 || !IsDigits(phoneNo)))
            {
                ShowError("The phone number must be exactly 11 digits, for example 01012345678.");
                return;
            }
            DateTime birthDate = DateTime.MinValue;
            bool hasDob = dob.Text.Trim() != "";
            if (hasDob)
            {
                if (!DateTime.TryParseExact(dob.Text.Trim(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out birthDate))
                {
                    ShowError("The date of birth is not a valid date. Pick it from the calendar.");
                    return;
                }
                if (birthDate > DateTime.Today)
                {
                    ShowError("The date of birth cannot be in the future. Pick an earlier date.");
                    return;
                }
            }

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand("Create_Admin", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@first_name", first));
            proc.Parameters.Add(new SqlParameter("@middle_name", middle == "" ? (object)DBNull.Value : middle));
            proc.Parameters.Add(new SqlParameter("@last_name", last));
            proc.Parameters.Add(new SqlParameter("@username", user));
            proc.Parameters.Add(new SqlParameter("@password", pass));
            proc.Parameters.Add(new SqlParameter("@email", mail));
            proc.Parameters.Add(new SqlParameter("@phone", phoneNo == "" ? (object)DBNull.Value : phoneNo));
            proc.Parameters.Add(new SqlParameter("@dob", hasDob ? (object)birthDate : DBNull.Value));
            proc.Parameters.Add(new SqlParameter("@role", role));
            proc.Parameters.Add(new SqlParameter("@zone_id",
                role == "Zone Admin" ? (object)Convert.ToInt32(newZone.SelectedValue) : DBNull.Value));
            proc.Parameters.Add(new SqlParameter("@super_admin_id", (int)Session["user"]));

            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    string where = role == "Zone Admin" ? " for the zone " + HttpUtility.HtmlEncode(newZone.SelectedItem.Text) : "";
                    ShowSuccess("The " + role + " account '" + HttpUtility.HtmlEncode(user) + "' for "
                              + HttpUtility.HtmlEncode(first + " " + last) + where + " was created. They can log in now.");
                    ClearCreateForm();
                    break;
                case -1:
                    ShowError("Some details are missing or not valid. Check the required fields, the phone (11 digits), "
                            + "the date of birth, and that a Zone Admin has a zone.");
                    break;
                case -2:
                    ShowError("This username or email is already used by another account. Choose another username or email.");
                    break;
                case -3:
                    ShowError("Only a Super Admin can create admins.");
                    break;
                default:
                    ShowCodeError(rc);
                    return;
            }
            BindAll();
        }

        private void ClearCreateForm()
        {
            firstName.Text = "";
            middleName.Text = "";
            lastName.Text = "";
            newUsername.Text = "";
            email.Text = "";
            phone.Text = "";
            dob.Text = "";
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
