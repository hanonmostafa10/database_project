using System;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Web;
using System.Web.Configuration;
using System.Web.UI.WebControls;

namespace WebApplication1
{
    public partial class Register : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                // Preselect the user type chosen on the start page
                string type = Request.QueryString["type"];
                if (type == "Customer" || type == "Partner" || type == "Rider")
                    regtype.SelectedValue = type;

                riderPanel.Visible = regtype.SelectedValue == "Rider";
                LoadZones();
            }
        }

        // Fill the zone list from h_ZoneList (the rider picks a zone by name)
        private void LoadZones()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand zonesCmd = new SqlCommand(
                "SELECT zone_id, zone_name, delivery_fee FROM h_ZoneList ORDER BY zone_name", conn);

            try
            {
                conn.Open();
                SqlDataReader rdr = zonesCmd.ExecuteReader();
                zone.Items.Clear();
                zone.Items.Add(new ListItem("-- Choose a zone --", ""));
                while (rdr.Read())
                {
                    zone.Items.Add(new ListItem(rdr.GetString(1), rdr.GetInt32(0).ToString()));
                }
                rdr.Close();
            }
            catch (SqlException)
            {
                msg.Text = "We could not load the zones right now. Please refresh the page in a moment.";
            }
            finally
            {
                conn.Close();
            }
        }

        // Show the rider fields only for a rider
        protected void regtype_Changed(object sender, EventArgs e)
        {
            riderPanel.Visible = regtype.SelectedValue == "Rider";
            msg.Text = "";
        }

        protected void register(object sender, EventArgs e)
        {
            msg.CssClass = "msg msg-error";
            string type = regtype.SelectedValue;

            string first = firstName.Text.Trim();
            string middle = middleName.Text.Trim();
            string last = lastName.Text.Trim();
            string user = regUsername.Text.Trim();
            string pass = regPassword.Text;
            string mail = email.Text.Trim();
            string phoneNo = phone.Text.Trim();

            // ---- Check the input before calling the database ----
            if (first == "" || last == "" || user == "" || pass == "" || mail == "")
            {
                msg.Text = "Please fill in your first name, last name, username, password and email.";
                return;
            }
            if (pass != confirmPassword.Text)
            {
                msg.Text = "The two passwords do not match. Type the same password in both boxes.";
                return;
            }
            if (!mail.Contains("@") || !mail.Contains("."))
            {
                msg.Text = "The email address does not look right. Enter it like name@example.com.";
                return;
            }
            if (phoneNo != "" && !IsDigits(phoneNo, 11))
            {
                msg.Text = "The phone number must be exactly 11 digits, for example 01012345678.";
                return;
            }

            DateTime birthDate = DateTime.MinValue;
            bool hasDob = dob.Text.Trim() != "";
            if (hasDob)
            {
                if (!DateTime.TryParseExact(dob.Text.Trim(), "yyyy-MM-dd", CultureInfo.InvariantCulture,
                                            DateTimeStyles.None, out birthDate))
                {
                    msg.Text = "The date of birth is not a valid date. Pick it from the calendar.";
                    return;
                }
                if (birthDate > DateTime.Today)
                {
                    msg.Text = "The date of birth cannot be in the future. Pick an earlier date.";
                    return;
                }
            }

            if (type == "Rider")
            {
                if (plateNo.Text.Trim() == "" || licenseNo.Text.Trim() == "" || zone.SelectedValue == "")
                {
                    msg.Text = "Please enter your plate number and license number and choose the zone you deliver in.";
                    return;
                }
            }

            // ---- Call the register procedure of this user type ----
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand registerProc = new SqlCommand(type + "_Register", conn);
            registerProc.CommandType = CommandType.StoredProcedure;

            registerProc.Parameters.Add(new SqlParameter("@first_name", first));
            registerProc.Parameters.Add(new SqlParameter("@middle_name", middle == "" ? (object)DBNull.Value : middle));
            registerProc.Parameters.Add(new SqlParameter("@last_name", last));
            registerProc.Parameters.Add(new SqlParameter("@username", user));
            registerProc.Parameters.Add(new SqlParameter("@password", pass));
            registerProc.Parameters.Add(new SqlParameter("@email", mail));
            registerProc.Parameters.Add(new SqlParameter("@phone", phoneNo == "" ? (object)DBNull.Value : phoneNo));
            registerProc.Parameters.Add(new SqlParameter("@dob", hasDob ? (object)birthDate : DBNull.Value));

            if (type == "Rider")
            {
                registerProc.Parameters.Add(new SqlParameter("@vehicle_type", vehicleType.SelectedValue));
                registerProc.Parameters.Add(new SqlParameter("@plate_no", plateNo.Text.Trim()));
                registerProc.Parameters.Add(new SqlParameter("@license_no", licenseNo.Text.Trim()));
                registerProc.Parameters.Add(new SqlParameter("@zone_id", Convert.ToInt32(zone.SelectedValue)));
            }

            // The RETURN code of the procedure
            SqlParameter returnCode = registerProc.Parameters.Add("@return", SqlDbType.Int);
            returnCode.Direction = ParameterDirection.ReturnValue;

            try
            {
                conn.Open();
                registerProc.ExecuteNonQuery();
            }
            catch (SqlException)
            {
                msg.Text = "We could not create your account right now. Please try again in a moment.";
                return;
            }
            finally
            {
                conn.Close();
            }

            // ---- Show a clear message for the return code (Table 3.1) ----
            int code = Convert.ToInt32(returnCode.Value);
            switch (code)
            {
                case 0:
                    msg.CssClass = "msg msg-success";
                    msg.Text = "Your " + type.ToLower() + " account '" + HttpUtility.HtmlEncode(user)
                             + "' was created. <a href=\"Login.aspx?type=" + type + "\">Log in now</a>.";
                    ClearForm();
                    break;
                case -1:
                    msg.Text = "Some details are missing or not valid. Check that every required field is filled, "
                             + "the phone has 11 digits and the date of birth is not in the future.";
                    break;
                case -2:
                    if (type == "Rider")
                        msg.Text = "This username, email, plate number or license number is already registered. "
                                 + "Change it, or log in if you already have an account.";
                    else
                        msg.Text = "This username or email is already used. Choose another username or email, "
                                 + "or log in if you already have an account.";
                    break;
                default:
                    msg.Text = "Your account could not be created. Check your details and try again.";
                    break;
            }
        }

        private static bool IsDigits(string s, int length)
        {
            if (s.Length != length) return false;
            foreach (char c in s)
                if (c < '0' || c > '9') return false;
            return true;
        }

        private void ClearForm()
        {
            firstName.Text = "";
            middleName.Text = "";
            lastName.Text = "";
            regUsername.Text = "";
            email.Text = "";
            phone.Text = "";
            dob.Text = "";
            plateNo.Text = "";
            licenseNo.Text = "";
            zone.SelectedIndex = 0;
        }
    }
}
