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
    // 3.4 g: how much did I earn in a period, how fast am I, and how do customers rate me?
    // The session check is in Rider.master (Page_Init), which runs before this page.
    public partial class RiderPerformance : System.Web.UI.Page
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
                ShowPeriod();
                ShowRatings();
            }
            catch (SqlException)
            {
                msg.Text = "We could not load your performance right now. Please refresh the page in a moment.";
            }
        }

        // ---- My_Earnings and My_Delivery_History for the period ----
        private void ShowPeriod()
        {
            DateTime from, to;
            if (!DateTime.TryParseExact(fromDate.Text.Trim(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out from)
                || !DateTime.TryParseExact(toDate.Text.Trim(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out to))
            {
                SetMsg(periodMsg, "msg-error", "Please pick both dates from the calendar.");
                periodPanel.Visible = false;
                return;
            }
            if (from > to)
            {
                SetMsg(periodMsg, "msg-error", "The start date is after the end date. Pick a start date on or before the end date.");
                periodPanel.Visible = false;
                return;
            }
            periodPanel.Visible = true;

            int riderId = (int)Session["user"];
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            // My_Earnings
            SqlCommand earningsFunc = new SqlCommand(
                "SELECT completed_deliveries, total_delivery_fees, total_earnings FROM dbo.My_Earnings(@rider_id, @from, @to)", conn);
            earningsFunc.Parameters.Add(new SqlParameter("@rider_id", riderId));
            earningsFunc.Parameters.Add(new SqlParameter("@from", SqlDbType.Date) { Value = from });
            earningsFunc.Parameters.Add(new SqlParameter("@to", SqlDbType.Date) { Value = to });
            DataTable earnings = new DataTable();
            new SqlDataAdapter(earningsFunc).Fill(earnings);

            // My_Delivery_History
            SqlCommand historyFunc = new SqlCommand(
                "SELECT * FROM dbo.My_Delivery_History(@rider_id, @from, @to) ORDER BY assigned_at DESC", conn);
            historyFunc.Parameters.Add(new SqlParameter("@rider_id", riderId));
            historyFunc.Parameters.Add(new SqlParameter("@from", SqlDbType.Date) { Value = from });
            historyFunc.Parameters.Add(new SqlParameter("@to", SqlDbType.Date) { Value = to });
            DataTable history = new DataTable();
            new SqlDataAdapter(historyFunc).Fill(history);

            DataRow e = earnings.Rows[0];
            int completed = Convert.ToInt32(e["completed_deliveries"]);
            statEarnings.Text = ((decimal)e["total_earnings"]).ToString("N2") + " EGP";
            statDeliveries.Text = completed.ToString();
            statFees.Text = ((decimal)e["total_delivery_fees"]).ToString("N2") + " EGP";

            historyGrid.DataSource = history;
            historyGrid.DataBind();

            SetMsg(periodMsg, completed == 0 ? "msg-warning" : "msg-success", completed == 0
                ? "You finished no deliveries between " + Nice(from) + " and " + Nice(to) + ", so you earned nothing in this period."
                : "Between " + Nice(from) + " and " + Nice(to) + " you finished " + completed + " deliver" + (completed == 1 ? "y" : "ies")
                  + " and earned <b>" + ((decimal)e["total_earnings"]).ToString("N2") + " EGP</b>.");

            // How fast am I: my average time from pick-up to delivery, compared with my zone
            int timed = 0;
            double minutes = 0;
            foreach (DataRow row in history.Rows)
            {
                if (row["tracking_time"] == DBNull.Value) continue;
                minutes += Convert.ToDouble(row["tracking_time"]);
                timed++;
            }
            if (timed == 0)
            {
                statSpeed.Text = "&ndash;";
                statSpeedLabel.Text = "No timed deliveries in this period";
                speedMsg.Text = "";
                speedMsg.CssClass = "msg";
                return;
            }
            double myAvg = minutes / timed;
            statSpeed.Text = myAvg.ToString("0.#") + " min";
            statSpeedLabel.Text = "My average time on the road";

            // ZoneDeliveryPerformance for my zone (from h_RiderProfile)
            SqlCommand zoneCmd = new SqlCommand(
                "SELECT z.avg_tracking_time FROM ZoneDeliveryPerformance z "
              + "JOIN dbo.h_RiderProfile(@rider_id) r ON r.zone_name = z.zone_name", conn);
            zoneCmd.Parameters.Add(new SqlParameter("@rider_id", riderId));
            object zoneAvg;
            try
            {
                conn.Open();
                zoneAvg = zoneCmd.ExecuteScalar();
            }
            finally
            {
                conn.Close();
            }

            if (zoneAvg == null || zoneAvg == DBNull.Value)
            {
                SetMsg(speedMsg, "msg-success", "You take " + myAvg.ToString("0.#") + " minutes on average from pick-up to delivery.");
                return;
            }
            double zone = Convert.ToDouble(zoneAvg);
            if (myAvg <= zone)
                SetMsg(speedMsg, "msg-success", "You take " + myAvg.ToString("0.#") + " minutes on average from pick-up to delivery. "
                     + "That is as fast as or faster than your zone's average of " + zone.ToString("0.#") + " minutes.");
            else
                SetMsg(speedMsg, "msg-warning", "You take " + myAvg.ToString("0.#") + " minutes on average from pick-up to delivery, "
                     + "slower than your zone's average of " + zone.ToString("0.#") + " minutes.");
        }

        // ---- My_Rating_Summary (all time) ----
        private void ShowRatings()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand ratingFunc = new SqlCommand("SELECT * FROM dbo.My_Rating_Summary(@rider_id)", conn);
            ratingFunc.Parameters.Add(new SqlParameter("@rider_id", (int)Session["user"]));
            DataTable rows = new DataTable();
            new SqlDataAdapter(ratingFunc).Fill(rows);
            DataRow r = rows.Rows[0];

            int count = Convert.ToInt32(r["ratings_count"]);
            if (count == 0)
            {
                SetMsg(ratingMsg, "msg-warning", "No customer has rated you yet.");
                starBars.Text = "";
                return;
            }
            decimal avg = (decimal)r["avg_rating"];
            SetMsg(ratingMsg, avg >= 3 ? "msg-success" : "msg-error",
                "Customers rate you <b>" + avg.ToString("0.0") + " &#9733;</b> on average from " + count + " rating(s)"
              + (avg >= 4 ? ". Great work!" : avg >= 3 ? "." : ". Try to be faster and friendlier to raise it."));
            starBars.Text = StarBars(count,
                Convert.ToInt32(r["five_star"]), Convert.ToInt32(r["four_star"]), Convert.ToInt32(r["three_star"]),
                Convert.ToInt32(r["two_star"]), Convert.ToInt32(r["one_star"]));
        }

        // One bar per star level
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
