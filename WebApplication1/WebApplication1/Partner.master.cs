using System;
using System.Web;
using System.Web.UI.WebControls;

namespace WebApplication1
{
    // Shared frame of every partner page: session check, who is signed in, menu and Log out.
    public partial class PartnerMaster : System.Web.UI.MasterPage
    {
        // Runs before the Page_Load of any partner page, so no partner page opens without a signed-in partner
        protected void Page_Init(object sender, EventArgs e)
        {
            if (Session["user"] == null || (string)Session["type"] != "Partner")
                Response.Redirect("~/Login.aspx?type=Partner");
        }

        protected void Page_PreRender(object sender, EventArgs e)
        {
            whoAmI.Text = HttpUtility.HtmlEncode((string)Session["username"] ?? "") + " &middot; Partner";

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
