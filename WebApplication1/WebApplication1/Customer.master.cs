using System;
using System.Data.SqlClient;
using System.Web;
using System.Web.Configuration;
using System.Web.UI.WebControls;

namespace WebApplication1
{
    // Shared frame of every customer page: session check, who is signed in, menu and Log out.
    public partial class CustomerMaster : System.Web.UI.MasterPage
    {
        // Runs before the Page_Load of any customer page, so no customer page opens without a signed-in customer
        protected void Page_Init(object sender, EventArgs e)
        {
            if (Session["user"] == null || (string)Session["type"] != "Customer")
            {
                Response.Redirect("~/Login.aspx?type=Customer");
                return;
            }

            if (Session["name"] == null)
            {
                // h_CustomerProfile: my name for the top bar
                string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
                SqlConnection conn = new SqlConnection(connStr);

                SqlCommand profileFunc = new SqlCommand("SELECT customer_name FROM dbo.h_CustomerProfile(@customer_id)", conn);
                profileFunc.Parameters.Add(new SqlParameter("@customer_id", (int)Session["user"]));
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
            whoAmI.Text = HttpUtility.HtmlEncode(name);

            // Highlight the menu entry of the current page (the business page belongs to Browse)
            string current = System.IO.Path.GetFileName(Request.Path);
            if (current.Equals("BusinessPage.aspx", StringComparison.OrdinalIgnoreCase)) current = "CustomerBrowse.aspx";
            if (current.Equals("CustomerCheckout.aspx", StringComparison.OrdinalIgnoreCase)) current = "CustomerCart.aspx";
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
