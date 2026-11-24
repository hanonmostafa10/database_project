using System;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Web;
using System.Web.Configuration;
using System.Web.UI.WebControls;

namespace WebApplication1
{
    // 3.4 b: register my business (again if Rejected), see its status, update hours / website, add a phone
    // The session check is in Partner.master (Page_Init), which runs before this page.
    public partial class PartnerHome : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadZones();
                ShowBusiness(true);
            }
        }

        // ================= Loading =================

        // h_MyBusiness: my business (null if I have none). Always read from the database for the signed-in partner.
        private DataRow ReadMyBusiness()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand businessFunc = new SqlCommand("SELECT * FROM dbo.h_MyBusiness(@partner_id)", conn);
            businessFunc.Parameters.Add(new SqlParameter("@partner_id", (int)Session["user"]));

            DataTable rows = new DataTable();
            new SqlDataAdapter(businessFunc).Fill(rows);
            return rows.Rows.Count == 0 ? null : rows.Rows[0];
        }

        // h_BusinessPhones
        private DataTable ReadPhones(int businessId)
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand phonesFunc = new SqlCommand("SELECT phone FROM dbo.h_BusinessPhones(@business_id) ORDER BY phone", conn);
            phonesFunc.Parameters.Add(new SqlParameter("@business_id", businessId));

            DataTable rows = new DataTable();
            new SqlDataAdapter(phonesFunc).Fill(rows);
            return rows;
        }

        // h_ZoneList for the register form
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

            regZone.Items.Clear();
            regZone.Items.Add(new ListItem("-- Choose a zone --", ""));
            foreach (DataRow row in rows.Rows)
                regZone.Items.Add(new ListItem((string)row["zone_name"], row["zone_id"].ToString()));
        }

        // Shows the status card and the right form. prefill = put the current values into the forms.
        private void ShowBusiness(bool prefill)
        {
            DataRow biz;
            DataTable phones = null;
            try
            {
                biz = ReadMyBusiness();
                if (biz != null) phones = ReadPhones((int)biz["business_id"]);
            }
            catch (SqlException)
            {
                ShowError("We could not load your business right now. Please refresh the page in a moment.");
                statusPanel.Visible = updatePanel.Visible = registerPanel.Visible = false;
                return;
            }

            // ---- No business yet: only the register form ----
            if (biz == null)
            {
                bizTitle.Text = "You have no business yet";
                statusBadge.Visible = false;
                SetMsg(statusText, "msg-warning", "Register your business below. Once an admin approves it, customers can order from you.");
                detailsPanel.Visible = false;
                updatePanel.Visible = false;
                registerPanel.Visible = true;
                registerTitle.Text = "Register my business";
                return;
            }

            string status = (string)biz["status"];
            string zone = HttpUtility.HtmlEncode((string)biz["zone_name"]);

            bizTitle.Text = HttpUtility.HtmlEncode((string)biz["business_name"]) + " ";
            statusBadge.Visible = true;
            statusBadge.Text = status;
            statusBadge.CssClass = "status status-" + status;

            switch (status)
            {
                case "Pending":
                    SetMsg(statusText, "msg-warning", "An admin of " + zone + " is reviewing your business. You can already add your "
                         + "products; customers will see them once your business is approved.");
                    break;
                case "Active":
                    SetMsg(statusText, "msg-success", "Your business is live. Customers in " + zone + " can order from you.");
                    break;
                case "Suspended":
                    SetMsg(statusText, "msg-error", "An admin suspended your business. <b>Reason: "
                         + HttpUtility.HtmlEncode(biz["suspension_reason"] as string ?? "not given") + "</b>. "
                         + "Your products are hidden from customers until an admin reinstates it. Contact support to solve the problem.");
                    break;
                case "Rejected":
                    SetMsg(statusText, "msg-error", "An admin rejected your business. Correct its details below and register it again.");
                    break;
            }

            // Details
            detailsPanel.Visible = true;
            string type = (string)biz["business_type"];
            dType.Text = type == "Restaurant"
                ? "Restaurant &middot; " + HttpUtility.HtmlEncode(biz["cuisine_type"] as string) + " &middot; " + HttpUtility.HtmlEncode(biz["food_category"] as string)
                : "Pharmacy &middot; " + HttpUtility.HtmlEncode(biz["pharmacy_type"] as string);
            dZone.Text = zone;
            dHours.Text = HoursText((TimeSpan)biz["opening_hour"], (TimeSpan)biz["closing_hour"]);
            dDelivery.Text = biz["expected_delivery_time"] + " minutes";
            dWebsite.Text = biz["link_website"] == DBNull.Value ? "<span class=\"muted\">none</span>" : HttpUtility.HtmlEncode((string)biz["link_website"]);
            dDescription.Text = biz["description"] == DBNull.Value ? "<span class=\"muted\">none</span>" : HttpUtility.HtmlEncode((string)biz["description"]);
            dPhones.Text = "";
            foreach (DataRow p in phones.Rows) dPhones.Text += (dPhones.Text == "" ? "" : ", ") + HttpUtility.HtmlEncode((string)p["phone"]);
            if (dPhones.Text == "") dPhones.Text = "<span class=\"muted\">none</span>";

            // A rejected business is registered again; any other one can be updated
            bool rejected = status == "Rejected";
            updatePanel.Visible = !rejected;
            registerPanel.Visible = rejected;
            registerTitle.Text = "Register my business again";

            if (!prefill) return;

            if (!rejected)
            {
                updOpen.Text = ((TimeSpan)biz["opening_hour"]).ToString(@"hh\:mm");
                updClose.Text = ((TimeSpan)biz["closing_hour"]).ToString(@"hh\:mm");
                updWebsite.Text = biz["link_website"] as string ?? "";
                updPhone.Text = "";
            }
            else
            {
                // Start from the rejected details so the partner only corrects what is wrong
                regName.Text = (string)biz["business_name"];
                regDescription.Text = biz["description"] as string ?? "";
                regWebsite.Text = biz["link_website"] as string ?? "";
                regZone.SelectedValue = biz["zone_id"].ToString();
                regOpen.Text = ((TimeSpan)biz["opening_hour"]).ToString(@"hh\:mm");
                regClose.Text = ((TimeSpan)biz["closing_hour"]).ToString(@"hh\:mm");
                regDelivery.Text = biz["expected_delivery_time"].ToString();
                regPhone.Text = phones.Rows.Count > 0 ? (string)phones.Rows[0]["phone"] : "";
                regType.SelectedValue = type;
                regCuisine.Text = biz["cuisine_type"] as string ?? "";
                regFoodCategory.Text = biz["food_category"] as string ?? "";
                regPharmacyType.Text = biz["pharmacy_type"] as string ?? "";
                regType_Changed(null, null);
            }
        }

        protected void regType_Changed(object sender, EventArgs e)
        {
            restaurantPanel.Visible = regType.SelectedValue == "Restaurant";
            pharmacyPanel.Visible = regType.SelectedValue == "Pharmacy";
        }

        // ================= Update_Business_Info =================

        protected void update_Click(object sender, EventArgs e)
        {
            TimeSpan open, close;
            string website = updWebsite.Text.Trim();
            string phone = updPhone.Text.Trim();

            if (!ReadTime(updOpen, out open) || !ReadTime(updClose, out close))
            {
                ShowError("Please enter the opening and closing times, for example 09:00 and 23:00.");
                return;
            }
            if (phone != "" && !IsDigits(phone, 11))
            {
                ShowError("The phone number must be exactly 11 digits, for example 01012345678.");
                return;
            }

            DataRow biz;
            try { biz = ReadMyBusiness(); }
            catch (SqlException) { ShowError("We could not reach the database right now. Please try again in a moment."); return; }

            if (biz == null || (string)biz["status"] == "Rejected")
            {
                ShowError("You have no business to update. Register your business first.");
                ShowBusiness(true);
                return;
            }

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand("Update_Business_Info", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@business_id", (int)biz["business_id"]));
            proc.Parameters.Add(new SqlParameter("@opening_hour", SqlDbType.Time) { Value = open });
            proc.Parameters.Add(new SqlParameter("@closing_hour", SqlDbType.Time) { Value = close });
            proc.Parameters.Add(new SqlParameter("@phone", phone == "" ? (object)DBNull.Value : phone));
            proc.Parameters.Add(new SqlParameter("@link_website", website == "" ? (object)DBNull.Value : website));

            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    ShowSuccess("Your business was updated. Hours: " + HoursText(open, close).ToLower() + "."
                              + (phone == "" ? "" : " The phone " + phone + " was added."));
                    ShowBusiness(true);
                    break;
                case -1:
                    ShowError("The phone number must be exactly 11 digits, for example 01012345678.");
                    break;
                case -2:
                    ShowError("The phone " + HttpUtility.HtmlEncode(phone) + " is already listed for your business. Enter a different number or leave it empty.");
                    break;
                default:
                    ShowCodeError(rc);
                    break;
            }
        }

        // ================= Register_Business =================

        protected void register_Click(object sender, EventArgs e)
        {
            string name = regName.Text.Trim();
            string description = regDescription.Text.Trim();
            string website = regWebsite.Text.Trim();
            string phone = regPhone.Text.Trim();
            string type = regType.SelectedValue;
            string cuisine = regCuisine.Text.Trim();
            string food = regFoodCategory.Text.Trim();
            string pharmacy = regPharmacyType.Text.Trim();
            TimeSpan open, close;
            int deliveryMinutes;

            // Check the input before calling the database
            if (name == "" || regZone.SelectedValue == "")
            {
                ShowError("Please enter the business name and choose its zone.");
                return;
            }
            if (!ReadTime(regOpen, out open) || !ReadTime(regClose, out close))
            {
                ShowError("Please enter the opening and closing times, for example 09:00 and 23:00.");
                return;
            }
            if (!int.TryParse(regDelivery.Text.Trim(), out deliveryMinutes) || deliveryMinutes <= 0 || deliveryMinutes > 1440)
            {
                ShowError("Please enter the expected delivery time in minutes, for example 30.");
                return;
            }
            if (phone != "" && !IsDigits(phone, 11))
            {
                ShowError("The phone number must be exactly 11 digits, for example 01012345678.");
                return;
            }
            if (type == "Restaurant" && (cuisine == "" || food == ""))
            {
                ShowError("A restaurant needs its cuisine and its food category.");
                return;
            }
            if (type == "Pharmacy" && pharmacy == "")
            {
                ShowError("A pharmacy needs its pharmacy type.");
                return;
            }

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand("Register_Business", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@partner_id", (int)Session["user"]));
            proc.Parameters.Add(new SqlParameter("@name", name));
            proc.Parameters.Add(new SqlParameter("@description", description == "" ? (object)DBNull.Value : description));
            proc.Parameters.Add(new SqlParameter("@link_website", website == "" ? (object)DBNull.Value : website));
            proc.Parameters.Add(new SqlParameter("@zone_id", Convert.ToInt32(regZone.SelectedValue)));
            proc.Parameters.Add(new SqlParameter("@opening_hour", SqlDbType.Time) { Value = open });
            proc.Parameters.Add(new SqlParameter("@closing_hour", SqlDbType.Time) { Value = close });
            proc.Parameters.Add(new SqlParameter("@expected_delivery_time", deliveryMinutes));
            proc.Parameters.Add(new SqlParameter("@phone", phone == "" ? (object)DBNull.Value : phone));
            proc.Parameters.Add(new SqlParameter("@business_type", type));
            proc.Parameters.Add(new SqlParameter("@cuisine_type", type == "Restaurant" ? (object)cuisine : DBNull.Value));
            proc.Parameters.Add(new SqlParameter("@food_category", type == "Restaurant" ? (object)food : DBNull.Value));
            proc.Parameters.Add(new SqlParameter("@pharmacy_type", type == "Pharmacy" ? (object)pharmacy : DBNull.Value));

            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    ShowSuccess(HttpUtility.HtmlEncode(name) + " was sent for approval. An admin of "
                              + HttpUtility.HtmlEncode(regZone.SelectedItem.Text) + " will review it; you will see the result on this page.");
                    ShowBusiness(true);
                    break;
                case -1:
                    ShowError("Some details are missing or not valid. Check the name, zone, hours, delivery time, the phone (11 digits) "
                            + "and the " + (type == "Restaurant" ? "cuisine and food category." : "pharmacy type."));
                    break;
                case -2:
                    ShowError("You already have a business, and a partner can have only one. You can register again only if it was rejected.");
                    ShowBusiness(false);
                    break;
                case -3:
                    ShowError("Only a partner account can register a business.");
                    break;
                default:
                    ShowCodeError(rc);
                    break;
            }
        }

        // ================= Helpers =================

        private static string HoursText(TimeSpan open, TimeSpan close)
        {
            if (open == close) return "Open 24 hours";
            return "From " + open.ToString(@"hh\:mm") + " to " + close.ToString(@"hh\:mm")
                 + (close < open ? " (after midnight)" : "");
        }

        private static bool ReadTime(TextBox box, out TimeSpan time)
        {
            return TimeSpan.TryParseExact(box.Text.Trim(), new[] { @"hh\:mm", @"hh\:mm\:ss", @"h\:mm" },
                                          CultureInfo.InvariantCulture, out time) && time < TimeSpan.FromDays(1);
        }

        private static bool IsDigits(string s, int length)
        {
            if (s.Length != length) return false;
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

        private static void SetMsg(Label label, string kind, string text)
        {
            label.CssClass = "msg " + kind;
            label.Text = text;
        }

        private void ShowSuccess(string text) { SetMsg(msg, "msg-success", text); }
        private void ShowError(string text) { SetMsg(msg, "msg-error", text); }
    }
}
