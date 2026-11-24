using System;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Text;
using System.Web;
using System.Web.Configuration;
using System.Web.UI.WebControls;

namespace WebApplication1
{
    // 3.4 d: which products bring my revenue in a period, and what do customers think of me?
    // The session check is in Partner.master (Page_Init), which runs before this page.
    public partial class PartnerPerformance : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (IsPostBack) return;

            fromDate.Text = DateTime.Today.AddMonths(-3).ToString("yyyy-MM-dd");
            toDate.Text = DateTime.Today.ToString("yyyy-MM-dd");
            ShowAll();
        }

        protected void show_Click(object sender, EventArgs e)
        {
            ShowAll();
        }

        private void ShowAll()
        {
            try
            {
                // h_MyBusiness: the business of the signed-in partner (never chosen by the user)
                int? businessId = MyBusinessId();
                if (businessId == null)
                {
                    reportPanel.Visible = false;
                    noBusinessPanel.Visible = true;
                    return;
                }
                ShowSales(businessId.Value);
                ShowFeedback(businessId.Value);
            }
            catch (SqlException)
            {
                msg.Text = "We could not load your performance right now. Please refresh the page in a moment.";
            }
        }

        private int? MyBusinessId()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand businessFunc = new SqlCommand("SELECT business_id FROM dbo.h_MyBusiness(@partner_id)", conn);
            businessFunc.Parameters.Add(new SqlParameter("@partner_id", (int)Session["user"]));
            try
            {
                conn.Open();
                object id = businessFunc.ExecuteScalar();
                return id == null ? (int?)null : (int)id;
            }
            finally
            {
                conn.Close();
            }
        }

        // ---- BusinessSalesReport ----
        private void ShowSales(int businessId)
        {
            DateTime from, to;
            if (!DateTime.TryParseExact(fromDate.Text.Trim(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out from)
                || !DateTime.TryParseExact(toDate.Text.Trim(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out to))
            {
                SetMsg(salesSummary, "msg-error", "Please pick both dates from the calendar.");
                salesGrid.Visible = false;
                return;
            }
            if (from > to)
            {
                SetMsg(salesSummary, "msg-error", "The start date is after the end date. Pick a start date on or before the end date.");
                salesGrid.Visible = false;
                return;
            }

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand salesFunc = new SqlCommand(
                "SELECT product_name, units_sold, revenue_per_product FROM dbo.BusinessSalesReport(@business_id, @from, @to) "
              + "ORDER BY revenue_per_product DESC, units_sold DESC", conn);
            salesFunc.Parameters.Add(new SqlParameter("@business_id", businessId));
            salesFunc.Parameters.Add(new SqlParameter("@from", SqlDbType.Date) { Value = from });
            salesFunc.Parameters.Add(new SqlParameter("@to", SqlDbType.Date) { Value = to });

            DataTable rows = new DataTable();
            new SqlDataAdapter(salesFunc).Fill(rows);

            if (rows.Rows.Count == 0)
            {
                SetMsg(salesSummary, "msg-warning", "You sold nothing between " + Nice(from) + " and " + Nice(to) + ". Choose a longer period.");
                salesGrid.Visible = false;
                return;
            }

            // Each product's share of the revenue, to see what brings the money
            decimal total = 0;
            int units = 0;
            foreach (DataRow row in rows.Rows)
            {
                total += (decimal)row["revenue_per_product"];
                units += Convert.ToInt32(row["units_sold"]);
            }
            rows.Columns.Add("share", typeof(decimal));
            foreach (DataRow row in rows.Rows)
                row["share"] = total == 0 ? 0 : Math.Round((decimal)row["revenue_per_product"] * 100 / total);

            salesGrid.Visible = true;
            salesGrid.DataSource = rows;
            salesGrid.DataBind();

            DataRow top = rows.Rows[0];
            SetMsg(salesSummary, "msg-success",
                "Between " + Nice(from) + " and " + Nice(to) + " you sold " + units + " item(s) for <b>" + total.ToString("N2")
              + " EGP</b>. Your top product is <b>" + HttpUtility.HtmlEncode((string)top["product_name"]) + "</b>, which brought "
              + top["share"] + "% of your revenue.");
        }

        // ---- BusinessFeedbackOverview ----
        private void ShowFeedback(int businessId)
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand feedbackFunc = new SqlCommand("SELECT * FROM dbo.BusinessFeedbackOverview(@business_id)", conn);
            feedbackFunc.Parameters.Add(new SqlParameter("@business_id", businessId));

            DataTable rows = new DataTable();
            new SqlDataAdapter(feedbackFunc).Fill(rows);
            DataRow f = rows.Rows[0];

            int count = Convert.ToInt32(f["number_of_feedbacks"]);
            if (count == 0)
            {
                SetMsg(feedbackSummary, "msg-warning", "No customer has left feedback yet.");
                starBars.Text = "";
                return;
            }

            decimal avg = (decimal)f["avg_rating"];
            string verdict = avg >= 4 ? "Customers love you." : avg >= 3 ? "Customers are mostly happy." : "Customers are not happy; read their feedback and improve.";
            SetMsg(feedbackSummary, avg >= 3 ? "msg-success" : "msg-error",
                "Your average rating is <b>" + avg.ToString("0.0") + " &#9733;</b> from " + count + " feedback(s). " + verdict);
            starBars.Text = StarBars(count,
                Convert.ToInt32(f["five_star"]), Convert.ToInt32(f["four_star"]), Convert.ToInt32(f["three_star"]),
                Convert.ToInt32(f["two_star"]), Convert.ToInt32(f["one_star"]));
        }

        // One bar per star level, e.g. "5 ★ ███████ 3"
        private static string StarBars(int total, params int[] counts)
        {
            StringBuilder html = new StringBuilder("<div class=\"stars\">");
            for (int i = 0; i < 5; i++)
            {
                int pct = total == 0 ? 0 : counts[i] * 100 / total;
                html.Append("<div class=\"star-row\"><span>" + (5 - i) + " &#9733;</span>"
                          + "<div class=\"bar\"><div style=\"width:" + pct + "%\"></div></div>"
                          + "<span>" + counts[i] + "</span></div>");
            }
            return html.Append("</div>").ToString();
        }

        private static void SetMsg(Label label, string kind, string text)
        {
            label.CssClass = "msg " + kind;
            label.Text = text;
        }

        private static string Nice(DateTime d)
        {
            return d.ToString("d MMM yyyy", CultureInfo.InvariantCulture);
        }
    }
}
