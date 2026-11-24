using System;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Web;
using System.Web.Configuration;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebApplication1
{
    // 3.3 c (zone comparison), d (revenue of a day), e (riders), f (market)
    // The session check is in Admin.master (Page_Init), which runs before this page.
    public partial class AdminInsights : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (IsPostBack) return;

            // Default periods: the last 3 months, and today for the revenue
            string from = DateTime.Today.AddMonths(-3).ToString("yyyy-MM-dd");
            string to = DateTime.Today.ToString("yyyy-MM-dd");
            zoneFrom.Text = from;
            zoneTo.Text = to;
            ridersFrom.Text = from;
            ridersTo.Text = to;
            revenueDate.Text = to;

            try
            {
                ShowZones();
                ShowRevenue();
                ShowRiders();
                ShowMarket();
            }
            catch (SqlException)
            {
                msg.Text = "We could not load the insights right now. Please refresh the page in a moment.";
            }
        }

        // ================= 3.3 c: Zone comparison =================

        protected void zoneBtn_Click(object sender, EventArgs e)
        {
            try { ShowZones(); }
            catch (SqlException) { msg.Text = "We could not load the zone comparison right now. Please try again in a moment."; }
        }

        private void ShowZones()
        {
            DateTime from, to;
            if (!ReadPeriod(zoneFrom, zoneTo, zoneSummary, out from, out to))
            {
                zoneGrid.Visible = false;
                return;
            }
            zoneGrid.Visible = true;

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            // BusinessesPerZone + ZoneDeliveryPerformance + ZoneOrderReport (called for every zone)
            SqlCommand zonesCmd = new SqlCommand(
                "SELECT b.zone_name, b.business_count, "
              + "ISNULL(r.number_of_orders, 0) AS number_of_orders, r.avg_order_total, "
              + "ISNULL(r.platform_commission, 0) AS platform_commission, "
              + "d.delivery_count, d.avg_tracking_time "
              + "FROM BusinessesPerZone b "
              + "JOIN ZoneDeliveryPerformance d ON d.zone_id = b.zone_id "
              + "OUTER APPLY dbo.ZoneOrderReport(b.zone_id, @from, @to) r "
              + "ORDER BY ISNULL(r.platform_commission, 0) DESC, ISNULL(r.number_of_orders, 0) DESC, b.zone_name", conn);
            zonesCmd.Parameters.Add(new SqlParameter("@from", SqlDbType.Date) { Value = from });
            zonesCmd.Parameters.Add(new SqlParameter("@to", SqlDbType.Date) { Value = to });

            DataTable rows = new DataTable();
            new SqlDataAdapter(zonesCmd).Fill(rows);
            zoneGrid.DataSource = rows;
            zoneGrid.DataBind();

            // Answer the question in words: strongest = most commission, needs help = fewest orders
            int totalOrders = 0;
            foreach (DataRow row in rows.Rows) totalOrders += Convert.ToInt32(row["number_of_orders"]);

            if (rows.Rows.Count == 0)
            {
                SetMsg(zoneSummary, "msg-warning", "There are no zones yet.");
            }
            else if (totalOrders == 0)
            {
                SetMsg(zoneSummary, "msg-warning", "No zone had orders between " + Nice(from) + " and " + Nice(to)
                     + ". Choose a longer period to compare the zones.");
            }
            else
            {
                DataRow strongest = rows.Rows[0];
                DataRow weakest = rows.Rows[0];
                foreach (DataRow row in rows.Rows)
                {
                    int orders = Convert.ToInt32(row["number_of_orders"]);
                    int weakestOrders = Convert.ToInt32(weakest["number_of_orders"]);
                    if (orders < weakestOrders
                        || (orders == weakestOrders && (int)row["business_count"] < (int)weakest["business_count"]))
                        weakest = row;
                }

                string text = "<b>Strongest zone: " + HttpUtility.HtmlEncode((string)strongest["zone_name"]) + "</b> with "
                            + strongest["number_of_orders"] + " order(s) and "
                            + ((decimal)strongest["platform_commission"]).ToString("N2") + " EGP commission. "
                            + "<b>Needs help: " + HttpUtility.HtmlEncode((string)weakest["zone_name"]) + "</b> with "
                            + weakest["number_of_orders"] + " order(s) and " + weakest["business_count"] + " active business(es).";
                SetMsg(zoneSummary, "msg-success", text);
            }
        }

        // ================= 3.3 d: Revenue of a day =================

        protected void revenueBtn_Click(object sender, EventArgs e)
        {
            try { ShowRevenue(); }
            catch (SqlException) { msg.Text = "We could not load the revenue right now. Please try again in a moment."; }
        }

        private void ShowRevenue()
        {
            DateTime day;
            if (!DateTime.TryParseExact(revenueDate.Text.Trim(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out day))
            {
                SetMsg(revenueSummary, "msg-error", "Please pick a day from the calendar.");
                revenueGrid.Visible = false;
                return;
            }
            revenueGrid.Visible = true;

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand revenueFunc = new SqlCommand(
                "SELECT zone_name, business_type, number_of_suborders, gross_sales, delivery_fees, platform_commission "
              + "FROM dbo.Daily_Revenue_Report(@day) ORDER BY gross_sales DESC", conn);
            revenueFunc.Parameters.Add(new SqlParameter("@day", SqlDbType.Date) { Value = day });

            DataTable rows = new DataTable();
            new SqlDataAdapter(revenueFunc).Fill(rows);
            revenueGrid.DataSource = rows;
            revenueGrid.DataBind();

            if (rows.Rows.Count == 0)
            {
                SetMsg(revenueSummary, "msg-warning", "There were no orders on " + Nice(day) + ", so there is no revenue. Choose another day.");
                revenueGrid.Visible = false;
                return;
            }

            decimal sales = 0, fees = 0, commission = 0;
            foreach (DataRow row in rows.Rows)
            {
                sales += (decimal)row["gross_sales"];
                fees += (decimal)row["delivery_fees"];
                commission += (decimal)row["platform_commission"];
            }
            DataRow top = rows.Rows[0];
            SetMsg(revenueSummary, "msg-success",
                "On " + Nice(day) + " customers bought <b>" + sales.ToString("N2") + " EGP</b> of products and paid "
              + fees.ToString("N2") + " EGP in delivery fees. The platform earned <b>" + commission.ToString("N2")
              + " EGP</b> in commission. Most of the money came from "
              + HttpUtility.HtmlEncode((string)top["business_type"]).ToLower() + "s in "
              + HttpUtility.HtmlEncode((string)top["zone_name"]) + ".");
        }

        // ================= 3.3 e: Riders =================

        protected void ridersBtn_Click(object sender, EventArgs e)
        {
            try { ShowRiders(); }
            catch (SqlException) { msg.Text = "We could not load the riders right now. Please try again in a moment."; }
        }

        private void ShowRiders()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            DateTime from, to;
            if (ReadPeriod(ridersFrom, ridersTo, ridersSummary, out from, out to))
            {
                SqlCommand topFunc = new SqlCommand(
                    "SELECT rider_rank, rider_name, completed_delivery_count FROM dbo.TopRiders(@from, @to) ORDER BY rider_rank", conn);
                topFunc.Parameters.Add(new SqlParameter("@from", SqlDbType.Date) { Value = from });
                topFunc.Parameters.Add(new SqlParameter("@to", SqlDbType.Date) { Value = to });

                DataTable top = new DataTable();
                new SqlDataAdapter(topFunc).Fill(top);
                topRidersGrid.DataSource = top;
                topRidersGrid.DataBind();
                topRidersGrid.Visible = true;
            }
            else
            {
                topRidersGrid.Visible = false;
            }

            // RiderPerformanceSummary: everyone, so the ones falling behind stand out
            SqlCommand summaryView = new SqlCommand(
                "SELECT rider_name, zone_name, completed_deliveries, avg_rating FROM RiderPerformanceSummary "
              + "ORDER BY completed_deliveries DESC, avg_rating DESC", conn);

            DataTable riders = new DataTable();
            new SqlDataAdapter(summaryView).Fill(riders);

            // A rider falls behind with fewer than half of the average deliveries, or a rating below 3 stars
            double average = 0;
            foreach (DataRow row in riders.Rows) average += Convert.ToInt32(row["completed_deliveries"]);
            if (riders.Rows.Count > 0) average /= riders.Rows.Count;

            riders.Columns.Add("verdict", typeof(string));
            int behind = 0;
            foreach (DataRow row in riders.Rows)
            {
                int done = Convert.ToInt32(row["completed_deliveries"]);
                bool lowRating = row["avg_rating"] != DBNull.Value && (decimal)row["avg_rating"] < 3;
                if (done < average / 2 || lowRating)
                {
                    row["verdict"] = lowRating ? "Falling behind: low rating" : "Falling behind: few deliveries";
                    behind++;
                }
                else
                {
                    row["verdict"] = "On track";
                }
            }
            allRidersGrid.DataSource = riders;
            allRidersGrid.DataBind();

            if (ridersSummary.CssClass.Contains("msg-error")) return; // keep the date error visible
            if (behind == 0)
                SetMsg(ridersSummary, "msg-success", "No rider is falling behind.");
            else
                SetMsg(ridersSummary, "msg-warning", behind + " rider(s) are falling behind: fewer than half of the average of "
                     + average.ToString("0.#") + " deliveries, or a rating below 3 stars.");
        }

        protected void allRidersGrid_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType != DataControlRowType.DataRow) return;
            if (((string)DataBinder.Eval(e.Row.DataItem, "verdict")).StartsWith("Falling"))
                e.Row.CssClass = "row-bad";
        }

        // ================= 3.3 f: Market =================

        private void ShowMarket()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand topView = new SqlCommand(
                "SELECT product_name, business_name, business_type, units_sold, total_revenue FROM TopSellingProducts "
              + "ORDER BY units_sold DESC, product_id", conn);
            DataTable products = new DataTable();
            new SqlDataAdapter(topView).Fill(products);
            topProductsGrid.DataSource = products;
            topProductsGrid.DataBind();

            SqlCommand ratingsView = new SqlCommand(
                "SELECT business_name, avg_rating, ratings_count FROM BusinessRatingsSummary", conn);
            DataTable ratings = new DataTable();
            new SqlDataAdapter(ratingsView).Fill(ratings);

            DataView loved = new DataView(ratings, "ratings_count > 0 AND avg_rating >= 4", "avg_rating DESC, ratings_count DESC", DataViewRowState.CurrentRows);
            DataView avoided = new DataView(ratings, "ratings_count > 0 AND avg_rating < 3", "avg_rating ASC, ratings_count DESC", DataViewRowState.CurrentRows);
            DataView unrated = new DataView(ratings, "ratings_count = 0", "", DataViewRowState.CurrentRows);

            lovedGrid.DataSource = loved;
            lovedGrid.DataBind();
            avoidedGrid.DataSource = avoided;
            avoidedGrid.DataBind();

            unratedNote.Text = unrated.Count == 0 ? "" : unrated.Count + " business(es) have no ratings yet.";
        }

        // ================= Helpers =================

        // Reads a From / To pair and checks it (shows the problem in the section's label)
        private bool ReadPeriod(TextBox fromBox, TextBox toBox, Label summary, out DateTime from, out DateTime to)
        {
            to = DateTime.MinValue;
            if (!DateTime.TryParseExact(fromBox.Text.Trim(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out from)
                || !DateTime.TryParseExact(toBox.Text.Trim(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out to))
            {
                SetMsg(summary, "msg-error", "Please pick both dates from the calendar.");
                return false;
            }
            if (from > to)
            {
                SetMsg(summary, "msg-error", "The start date is after the end date. Pick a start date on or before the end date.");
                return false;
            }
            summary.CssClass = "msg";
            summary.Text = "";
            return true;
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
