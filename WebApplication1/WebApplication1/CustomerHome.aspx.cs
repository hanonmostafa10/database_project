using System;
using System.Data;
using System.Data.SqlClient;
using System.Web;
using System.Web.Configuration;

namespace WebApplication1
{
    // 3.5 a: my home page shows my name, my active address and my wallet balance
    // The session check is in Customer.master (Page_Init), which runs before this page.
    public partial class CustomerHome : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (IsPostBack) return;

            int customerId = (int)Session["user"];
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            // h_CustomerProfile
            SqlCommand profileFunc = new SqlCommand(
                "SELECT customer_name, wallet_balance, active_address, active_zone FROM dbo.h_CustomerProfile(@customer_id)", conn);
            profileFunc.Parameters.Add(new SqlParameter("@customer_id", customerId));

            // My_Order_History: how many of my orders are on the way
            SqlCommand ordersFunc = new SqlCommand(
                "SELECT COUNT(*) FROM dbo.My_Order_History(@customer_id) WHERE status IN ('Placed', 'In Progress')", conn);
            ordersFunc.Parameters.Add(new SqlParameter("@customer_id", customerId));

            try
            {
                DataTable rows = new DataTable();
                new SqlDataAdapter(profileFunc).Fill(rows);
                if (rows.Rows.Count == 0) return;
                DataRow r = rows.Rows[0];

                Session["name"] = (string)r["customer_name"];
                customerName.Text = HttpUtility.HtmlEncode((string)r["customer_name"]);
                wallet.Text = ((decimal)r["wallet_balance"]).ToString("N2") + " EGP";

                if (r["active_address"] == DBNull.Value)
                {
                    activeAddress.Text = "No address yet";
                    activeZone.Text = "Active address";
                    addressHint.Text = "Add an address first: businesses, carts and deliveries depend on your active address. "
                                     + "<a href=\"CustomerAddresses.aspx\">Add my address</a>";
                }
                else
                {
                    activeAddress.Text = HttpUtility.HtmlEncode((string)r["active_address"]);
                    activeZone.Text = "Active address &middot; " + HttpUtility.HtmlEncode((string)r["active_zone"]);
                }

                conn.Open();
                onTheWay.Text = ordersFunc.ExecuteScalar().ToString();
            }
            catch (SqlException)
            {
                msg.Text = "We could not load your account right now. Please refresh the page in a moment.";
            }
            finally
            {
                conn.Close();
            }
        }
    }
}
