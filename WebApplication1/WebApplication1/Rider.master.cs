using System;
using System.Data.SqlClient;
using System.Web;
using System.Web.Configuration;
using System.Web.UI.WebControls;

namespace WebApplication1
{
    // Shared frame of every rider page: session check, who is signed in, menu and Log out.
    public partial class RiderMaster : System.Web.UI.MasterPage
    {
        // Runs before the Page_Load of any rider page, so no rider page opens without a signed-in rider
        protected void Page_Init(object sender, EventArgs e)
        {
            if (Session["user"] == null || (string)Session["type"] != "Rider")
            {
                Response.Redirect("~/Login.aspx?type=Rider");
                return;
            }

            if (Session["name"] == null)
            {
                // h_RiderProfile: my name for the top bar
                string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
                SqlConnection conn = new SqlConnection(connStr);

                SqlCommand profileFunc = new SqlCommand("SELECT rider_name FROM dbo.h_RiderProfile(@rider_id)", conn);
                profileFunc.Parameters.Add(new SqlParameter("@rider_id", (int)Session["user"]));
                try
                {
                    conn.Open();
                    Session["name"] = profileFunc.ExecuteScalar() as string;
                }
                catch (SqlException)
                {
                    // The page itself shows a message if it cannot reach the database
                }
                finally
                {
                    conn.Close();
                }
            }
        }

        protected void Page_PreRender(object sender, EventArgs e)
        {
            string name = (string)Session["name"] ?? (string)Session["username"] ?? "";
            whoAmI.Text = HttpUtility.HtmlEncode(name) + " &middot; Rider";

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
