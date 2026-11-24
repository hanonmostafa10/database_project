using System;
using System.Data;
using System.Data.SqlClient;
using System.Web;
using System.Web.Configuration;

namespace WebApplication1
{
    // 3.2 a (admin home page) and 3.3 a (platform dashboard)
    // The session check is in Admin.master (Page_Init), which runs before this page.
    public partial class AdminHome : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (IsPostBack) return;

            int adminId = (int)Session["user"];

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            try
            {
                conn.Open();
                ShowProfile(conn, adminId);
                int mismatches = ShowOrderTotals(conn);
                ShowHealth(conn, mismatches);
            }
            catch (SqlException)
            {
                msg.Text = "We could not load the dashboard right now. Please refresh the page in a moment.";
            }
            finally
            {
                conn.Close();
            }
        }

        // ---- 3.2 a: h_AdminProfile -> my name, my role and my zone ----
        private void ShowProfile(SqlConnection conn, int adminId)
        {
            SqlCommand profileFunc = new SqlCommand(
                "SELECT admin_name, role, zone_id, zone_name FROM dbo.h_AdminProfile(@admin_id)", conn);
            profileFunc.Parameters.Add(new SqlParameter("@admin_id", adminId));

            SqlDataReader rdr = profileFunc.ExecuteReader();
            if (rdr.Read())
            {
                string name = rdr.GetString(0);
                string role = rdr.GetString(1);

                // Remember my role: pages use it to hide Super Admin features from a Zone Admin
                Session["name"] = name;
                Session["role"] = role;
                Session["zoneId"] = rdr.IsDBNull(2) ? null : (object)rdr.GetInt32(2);
                Session["zoneName"] = rdr.IsDBNull(3) ? null : rdr.GetString(3);

                welcome.Text = "Welcome, " + HttpUtility.HtmlEncode(name);

                // Super Admin features are hidden for a Zone Admin
                quickAccounts.Visible = role == "Super Admin";
                roleBadge.Text = role;
                if (role == "Zone Admin")
                    zoneLine.Text = "&nbsp; You manage the zone <b>"
                                  + HttpUtility.HtmlEncode(rdr.IsDBNull(3) ? "(none)" : rdr.GetString(3)) + "</b>.";
                else
                    zoneLine.Text = "&nbsp; You manage all zones.";
            }
            rdr.Close();
        }

        // ---- 3.3 a: Reconcile_Order_Totals -> orders whose totals do not match ----
        // Returns how many orders do not match.
        private int ShowOrderTotals(SqlConnection conn)
        {
            SqlCommand reconcileFunc = new SqlCommand(
                "SELECT order_id, expected_total, order_total, payment_amount FROM dbo.Reconcile_Order_Totals() ORDER BY order_id", conn);

            DataTable rows = new DataTable();
            new SqlDataAdapter(reconcileFunc).Fill(rows);

            // Say in words what is wrong with each order
            rows.Columns.Add("problem", typeof(string));
            foreach (DataRow row in rows.Rows)
            {
                if (row["payment_amount"] == DBNull.Value)
                    row["problem"] = "No payment was recorded for this order.";
                else if ((decimal)row["order_total"] != (decimal)row["expected_total"])
                    row["problem"] = "The order total is not the sum of its parts and fees minus the discount.";
                else
                    row["problem"] = "The amount paid is different from the order total.";
            }

            if (rows.Rows.Count == 0)
            {
                totalsStatus.CssClass = "msg msg-success";
                totalsStatus.Text = "All order totals match their parts and their payments.";
                mismatchGrid.Visible = false;
            }
            else
            {
                totalsStatus.CssClass = "msg msg-error";
                totalsStatus.Text = "<b>Warning:</b> " + rows.Rows.Count + " order(s) have totals that do not match. "
                                  + "Check these orders and their payments before they are refunded or reported.";
                mismatchGrid.DataSource = rows;
                mismatchGrid.DataBind();
            }
            return rows.Rows.Count;
        }

        // ---- 3.3 a: Platform_Health_Snapshot -> is the platform healthy today? ----
        private void ShowHealth(SqlConnection conn, int mismatches)
        {
            SqlCommand healthFunc = new SqlCommand(
                "SELECT active_businesses, available_riders, orders_today, avg_delivery_time_today, low_ratings_today "
              + "FROM dbo.Platform_Health_Snapshot()", conn);

            SqlDataReader rdr = healthFunc.ExecuteReader();
            if (!rdr.Read())
            {
                rdr.Close();
                return;
            }

            int businesses = rdr.GetInt32(0);
            int riders = rdr.GetInt32(1);
            int orders = rdr.GetInt32(2);
            bool hasAvg = !rdr.IsDBNull(3);
            decimal avgTime = hasAvg ? rdr.GetDecimal(3) : 0;
            int lowRatings = rdr.GetInt32(4);
            rdr.Close();

            statBusinesses.Text = businesses.ToString();
            statRiders.Text = riders.ToString();
            statOrders.Text = orders.ToString();
            statLowRatings.Text = lowRatings.ToString();
            if (hasAvg)
            {
                statAvgTime.Text = avgTime.ToString("0.#") + " min";
                statAvgTimeLabel.Text = "Average delivery time today";
            }
            else
            {
                statAvgTime.Text = "&ndash;";
                statAvgTimeLabel.Text = "No deliveries finished today yet";
            }

            // List everything that is wrong, in plain words
            issuesList.Items.Clear();
            if (mismatches > 0)
                issuesList.Items.Add(mismatches + " order(s) have totals that do not match (see the order totals check below).");
            if (businesses == 0)
            {
                tileBusinesses.CssClass = "stat bad";
                issuesList.Items.Add("No business is active, so customers cannot order anything. Approve pending businesses.");
            }
            if (riders == 0)
            {
                tileRiders.CssClass = "stat bad";
                issuesList.Items.Add("No rider is available, so customers cannot check out. Ask riders to switch to available.");
            }
            if (lowRatings > 0)
            {
                tileLowRatings.CssClass = "stat bad";
                issuesList.Items.Add(lowRatings + " customer(s) gave a rating of 2 stars or less today.");
            }

            if (mismatches > 0)
            {
                healthStatus.CssClass = "msg msg-error";
                healthStatus.Text = "Something needs your attention today.";
            }
            else if (issuesList.Items.Count > 0)
            {
                healthStatus.CssClass = "msg msg-warning";
                healthStatus.Text = "The platform is running, but a few things need a look.";
            }
            else
            {
                healthStatus.CssClass = "msg msg-success";
                healthStatus.Text = "The platform is healthy today. Nothing is wrong.";
            }
            issuesList.Visible = issuesList.Items.Count > 0;
        }
    }
}
