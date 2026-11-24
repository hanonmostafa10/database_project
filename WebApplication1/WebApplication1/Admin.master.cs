using System;
using System.Data;
using System.Data.SqlClient;
using System.Web;
using System.Web.Configuration;
using System.Web.UI.WebControls;

namespace WebApplication1
{
    // Shared frame of every admin page: session check, who is signed in, menu and Log out.
    public partial class AdminMaster : System.Web.UI.MasterPage
    {
        // Runs before the Page_Load of any admin page, so no admin page opens without a signed-in admin
        protected void Page_Init(object sender, EventArgs e)
        {
            if (Session["user"] == null || (string)Session["type"] != "Admin")
            {
                Response.Redirect("~/Login.aspx?type=Admin");
                return;
            }

            if (Session["role"] == null)
                LoadProfile();
        }

        // Read my name, role and zone from h_AdminProfile and remember them for every admin page
        private void LoadProfile()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand profileFunc = new SqlCommand(
                "SELECT admin_name, role, zone_id, zone_name FROM dbo.h_AdminProfile(@admin_id)", conn);
            profileFunc.Parameters.Add(new SqlParameter("@admin_id", (int)Session["user"]));

            bool found = false;
            try
            {
                conn.Open();
                SqlDataReader rdr = profileFunc.ExecuteReader();
                if (rdr.Read())
                {
                    found = true;
                    Session["name"] = rdr.GetString(0);
                    Session["role"] = rdr.GetString(1);
                    Session["zoneId"] = rdr.IsDBNull(2) ? null : (object)rdr.GetInt32(2);
                    Session["zoneName"] = rdr.IsDBNull(3) ? null : rdr.GetString(3);
                }
                rdr.Close();
            }
            catch (SqlException)
            {
                // The page itself shows a message if it cannot reach the database
                return;
            }
            finally
            {
                conn.Close();
            }

            // The account is no longer an admin: sign out
            if (!found)
            {
                Session.Clear();
                Response.Redirect("~/Login.aspx?type=Admin");
            }
        }

        protected void Page_PreRender(object sender, EventArgs e)
        {
            // Show who is signed in, e.g. "Karim Adel · Zone Admin (Maadi)"
            string who = Session["name"] == null ? "Admin" : HttpUtility.HtmlEncode((string)Session["name"]);
            if (Session["role"] != null)
            {
                who += " &middot; " + Session["role"];
                if (Session["zoneName"] != null)
                    who += " (" + HttpUtility.HtmlEncode((string)Session["zoneName"]) + ")";
            }
            whoAmI.Text = who;

            // Super Admin only features are hidden for a Zone Admin
            navAccounts.Visible = (string)Session["role"] == "Super Admin";

            // Highlight the menu entry of the current page
            string current = System.IO.Path.GetFileName(Request.Path);
            foreach (var control in navHome.Parent.Controls)
            {
                HyperLink link = control as HyperLink;
                if (link != null && link.NavigateUrl.EndsWith(current, StringComparison.OrdinalIgnoreCase))
                    link.CssClass = "active";
            }
        }

        protected void logout(object sender, EventArgs e)
        {
            Session.Clear();
            Session.Abandon();
            Response.Redirect("~/Default.aspx");
        }
    }
}
