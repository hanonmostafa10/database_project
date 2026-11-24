using System;
using System.Data;
using System.Data.SqlClient;
using System.Web;
using System.Web.Configuration;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebApplication1
{
    // 3.6 a: search for businesses by name or browse them by product category
    // The session check is in Customer.master (Page_Init), which runs before this page.
    public partial class CustomerBrowse : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (IsPostBack) return;

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            // h_CustomerProfile: my active address (searching and browsing depend on it)
            SqlCommand profileFunc = new SqlCommand(
                "SELECT active_address_id, active_address, active_zone FROM dbo.h_CustomerProfile(@customer_id)", conn);
            profileFunc.Parameters.Add(new SqlParameter("@customer_id", (int)Session["user"]));

            // h_ProductCategories (Team_115.sql): the categories to browse by
            SqlCommand categoriesView = new SqlCommand("SELECT category FROM h_ProductCategories ORDER BY category", conn);

            DataTable profile = new DataTable();
            DataTable categories = new DataTable();
            try
            {
                new SqlDataAdapter(profileFunc).Fill(profile);
                new SqlDataAdapter(categoriesView).Fill(categories);
            }
            catch (SqlException)
            {
                ShowError("We could not load the businesses right now. Please refresh the page in a moment.");
                searchPanel.Visible = false;
                return;
            }

            if (profile.Rows.Count == 0 || profile.Rows[0]["active_address_id"] == DBNull.Value)
            {
                addressLine.Text = "";
                ShowError("You have no address yet. <a href=\"CustomerAddresses.aspx\">Add your address</a> to see the businesses that deliver to you.");
                searchPanel.Visible = false;
                return;
            }

            DataRow p = profile.Rows[0];
            ViewState["addressId"] = (int)p["active_address_id"];
            addressLine.Text = "Delivering to <b>" + HttpUtility.HtmlEncode((string)p["active_address"]) + "</b> ("
                             + HttpUtility.HtmlEncode((string)p["active_zone"]) + "). <a href=\"CustomerAddresses.aspx\">Change</a>";

            category.Items.Clear();
            category.Items.Add(new ListItem("-- Choose a category --", ""));
            foreach (DataRow row in categories.Rows)
                category.Items.Add(new ListItem((string)row["category"], (string)row["category"]));
        }

        // ================= Search_Platform =================

        protected void search_Click(object sender, EventArgs e)
        {
            string word = keyword.Text.Trim();
            if (word == "")
            {
                ShowError("Type part of a business name to search, for example Pizza.");
                resultsPanel.Visible = false;
                return;
            }
            msg.Text = "";

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            // Search_Platform ranks the matches; BusinessRatingsSummary and h_BusinessDetails add rating and open now
            SqlCommand searchFunc = new SqlCommand(
                "SELECT s.business_id, s.business_name, d.zone_name, d.is_open_now, d.expected_delivery_time, "
              + "r.avg_rating, r.ratings_count, CAST(1 AS BIT) AS same_zone, NULL AS zone_avg_delivery_time "
              + "FROM dbo.Search_Platform(@customer_id, @keyword) s "
              + "JOIN BusinessRatingsSummary r ON r.business_id = s.business_id "
              + "CROSS APPLY dbo.h_BusinessDetails(s.business_id) d "
              + "ORDER BY s.priority, s.business_id", conn);
            searchFunc.Parameters.Add(new SqlParameter("@customer_id", (int)Session["user"]));
            searchFunc.Parameters.Add(new SqlParameter("@keyword", word));

            DataTable rows = new DataTable();
            try
            {
                new SqlDataAdapter(searchFunc).Fill(rows);
            }
            catch (SqlException)
            {
                ShowError("We could not search right now. Please try again in a moment.");
                return;
            }

            ShowResults(rows, rows.Rows.Count == 0
                ? "No business in your zone matches \"" + HttpUtility.HtmlEncode(word) + "\". Try a shorter word or browse by category."
                : rows.Rows.Count + " business(es) in your zone match \"" + HttpUtility.HtmlEncode(word) + "\"");
        }

        // ================= Nearby_Businesses_By_Category =================

        protected void browse_Click(object sender, EventArgs e)
        {
            if (category.SelectedValue == "")
            {
                ShowError("Choose a category to browse, for example Pizza.");
                resultsPanel.Visible = false;
                return;
            }
            if (ViewState["addressId"] == null) return;
            msg.Text = "";

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            // Businesses of my zone first, then the fastest zones
            SqlCommand nearbyFunc = new SqlCommand(
                "SELECT n.business_id, n.business_name, n.zone_name, n.same_zone, n.zone_avg_delivery_time, "
              + "d.is_open_now, d.expected_delivery_time, r.avg_rating, r.ratings_count "
              + "FROM dbo.Nearby_Businesses_By_Category(@address_id, @category) n "
              + "JOIN BusinessRatingsSummary r ON r.business_id = n.business_id "
              + "CROSS APPLY dbo.h_BusinessDetails(n.business_id) d "
              + "ORDER BY n.same_zone DESC, n.zone_avg_delivery_time, n.business_id", conn);
            nearbyFunc.Parameters.Add(new SqlParameter("@address_id", (int)ViewState["addressId"]));
            nearbyFunc.Parameters.Add(new SqlParameter("@category", category.SelectedValue));

            DataTable rows = new DataTable();
            try
            {
                new SqlDataAdapter(nearbyFunc).Fill(rows);
            }
            catch (SqlException)
            {
                ShowError("We could not load the businesses right now. Please try again in a moment.");
                return;
            }

            string cat = HttpUtility.HtmlEncode(category.SelectedValue);
            ShowResults(rows, rows.Rows.Count == 0
                ? "No business sells " + cat + " right now. Choose another category."
                : "Businesses selling " + cat + " (your zone first)");
        }

        private void ShowResults(DataTable rows, string title)
        {
            resultsPanel.Visible = true;
            resultsTitle.Text = title;
            resultsGrid.DataSource = rows;
            resultsGrid.DataBind();
            resultsGrid.Visible = rows.Rows.Count > 0;
        }

        protected void resultsGrid_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType != DataControlRowType.DataRow) return;

            bool open = Convert.ToBoolean(DataBinder.Eval(e.Row.DataItem, "is_open_now"));
            Label openNow = (Label)e.Row.FindControl("openNow");
            openNow.Text = open ? "Open" : "Closed";
            openNow.CssClass = open ? "status status-Active" : "status status-Rejected";

            // A business of another zone cannot deliver to my active address
            Label delivery = (Label)e.Row.FindControl("delivery");
            if (!Convert.ToBoolean(DataBinder.Eval(e.Row.DataItem, "same_zone")))
            {
                delivery.Text = "Does not deliver to your address";
                delivery.CssClass = "muted";
            }
            else
            {
                delivery.Text = "About " + DataBinder.Eval(e.Row.DataItem, "expected_delivery_time") + " min";
            }
        }

        private void ShowError(string text)
        {
            msg.CssClass = "msg msg-error";
            msg.Text = text;
        }
    }
}
