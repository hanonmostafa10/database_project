using System;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Web;
using System.Web.Configuration;
using System.Web.UI.WebControls;

namespace WebApplication1
{
    // 3.3 b: view all zones with their fees; create a zone and change a zone's fee (Super Admin only)
    // The session check is in Admin.master (Page_Init), which runs before this page.
    public partial class AdminZones : System.Web.UI.Page
    {
        private bool IsSuperAdmin
        {
            get { return (string)Session["role"] == "Super Admin"; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            // Super Admin features are hidden for a Zone Admin
            superAdminPanel.Visible = IsSuperAdmin;
            zoneAdminNote.Text = IsSuperAdmin ? "" : "Only a Super Admin can create zones or change delivery fees.";

            if (!IsPostBack)
                BindZones();
        }

        // h_ZoneList: the table and the zone list of the fee form
        private void BindZones()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand zonesView = new SqlCommand(
                "SELECT zone_id, zone_name, delivery_fee FROM h_ZoneList ORDER BY zone_name", conn);

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

            zonesGrid.DataSource = rows;
            zonesGrid.DataBind();

            feeZone.Items.Clear();
            feeZone.Items.Add(new ListItem("-- Choose a zone --", ""));
            foreach (DataRow row in rows.Rows)
            {
                feeZone.Items.Add(new ListItem(
                    (string)row["zone_name"] + " (now " + ((decimal)row["delivery_fee"]).ToString("N2") + " EGP)",
                    row["zone_id"].ToString()));
            }
        }

        // ================= Create_Zone =================

        protected void createZone_Click(object sender, EventArgs e)
        {
            string name = newZoneName.Text.Trim();
            decimal fee;

            if (name == "")
            {
                ShowError("Please enter the name of the new zone.");
                return;
            }
            if (!decimal.TryParse(newZoneFee.Text.Trim(), NumberStyles.Number, CultureInfo.InvariantCulture, out fee) || fee < 0 || fee > 99999999.99m)
            {
                ShowError("Please enter a delivery fee of 0 EGP or more.");
                return;
            }

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand("Create_Zone", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@zone_name", name));
            proc.Parameters.Add(new SqlParameter("@delivery_fee", fee));
            proc.Parameters.Add(new SqlParameter("@super_admin_id", (int)Session["user"]));

            string safeName = HttpUtility.HtmlEncode(name);
            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    ShowSuccess("The zone " + safeName + " was created with a delivery fee of " + fee.ToString("N2") + " EGP.");
                    newZoneName.Text = "";
                    newZoneFee.Text = "";
                    break;
                case -1:
                    ShowError("Please enter a zone name and a delivery fee of 0 EGP or more.");
                    break;
                case -2:
                    ShowError("A zone called " + safeName + " already exists. Choose another name.");
                    break;
                case -3:
                    ShowError("Only a Super Admin can create zones.");
                    break;
                default:
                    ShowCodeError(rc);
                    return;
            }
            BindZones();
        }

        // ================= Update_Zone_Fee =================

        protected void updateFee_Click(object sender, EventArgs e)
        {
            decimal fee;

            if (feeZone.SelectedValue == "")
            {
                ShowError("Please choose the zone whose fee you want to change.");
                return;
            }
            if (!decimal.TryParse(newFee.Text.Trim(), NumberStyles.Number, CultureInfo.InvariantCulture, out fee) || fee < 0 || fee > 99999999.99m)
            {
                ShowError("Please enter a delivery fee of 0 EGP or more.");
                return;
            }

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand("Update_Zone_Fee", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@zone_id", Convert.ToInt32(feeZone.SelectedValue)));
            proc.Parameters.Add(new SqlParameter("@new_fee", fee));
            proc.Parameters.Add(new SqlParameter("@super_admin_id", (int)Session["user"]));

            string zoneName = feeZone.SelectedItem.Text;
            zoneName = HttpUtility.HtmlEncode(zoneName.Substring(0, zoneName.LastIndexOf(" (now")));

            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    ShowSuccess("The delivery fee of " + zoneName + " is now " + fee.ToString("N2")
                              + " EGP. It applies to new orders; orders already placed keep their fee.");
                    newFee.Text = "";
                    break;
                case -1:
                    ShowError("This zone does not exist anymore, or the fee is not valid. Choose a zone and enter a fee of 0 EGP or more.");
                    break;
                case -3:
                    ShowError("Only a Super Admin can change delivery fees.");
                    break;
                default:
                    ShowCodeError(rc);
                    return;
            }
            BindZones();
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
