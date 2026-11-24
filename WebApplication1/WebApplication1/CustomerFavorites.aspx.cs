using System;
using System.Data;
using System.Data.SqlClient;
using System.Web;
using System.Web.Configuration;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebApplication1
{
    // 3.6 b: add or remove favorites, view my favorite products and the products recommended for me
    // The session check is in Customer.master (Page_Init), which runs before this page.
    public partial class CustomerFavorites : System.Web.UI.Page
    {
        private int CustomerId { get { return (int)Session["user"]; } }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
                BindAll();
        }

        private void BindAll()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            // My_Favorites
            SqlCommand favProductsFunc = new SqlCommand(
                "SELECT product_id, product_name, business_name, is_orderable FROM dbo.My_Favorites(@customer_id) ORDER BY product_name", conn);
            favProductsFunc.Parameters.Add(new SqlParameter("@customer_id", CustomerId));
            // h_MyFavoriteBusinesses (Team_115.sql)
            SqlCommand favBusinessesFunc = new SqlCommand(
                "SELECT business_id, business_name, zone_name, status FROM dbo.h_MyFavoriteBusinesses(@customer_id) ORDER BY business_name", conn);
            favBusinessesFunc.Parameters.Add(new SqlParameter("@customer_id", CustomerId));
            // Recommended_Products
            SqlCommand recommendedFunc = new SqlCommand(
                "SELECT product_id, product_name, business_name, category, final_price FROM dbo.Recommended_Products(@customer_id)", conn);
            recommendedFunc.Parameters.Add(new SqlParameter("@customer_id", CustomerId));

            DataTable favProducts = new DataTable();
            DataTable favBusinesses = new DataTable();
            DataTable recommended = new DataTable();
            try
            {
                new SqlDataAdapter(favProductsFunc).Fill(favProducts);
                new SqlDataAdapter(favBusinessesFunc).Fill(favBusinesses);
                new SqlDataAdapter(recommendedFunc).Fill(recommended);
            }
            catch (SqlException)
            {
                ShowError("We could not load your favorites right now. Please refresh the page in a moment.");
                return;
            }

            // A recommended product that is already a favorite does not need the button
            foreach (DataRow f in favProducts.Rows)
                foreach (DataRow r in recommended.Select("product_id = " + (int)f["product_id"]))
                    r.Delete();
            recommended.AcceptChanges();

            favProductsGrid.DataSource = favProducts;
            favProductsGrid.DataBind();
            favBusinessesGrid.DataSource = favBusinesses;
            favBusinessesGrid.DataBind();
            recommendedGrid.DataSource = recommended;
            recommendedGrid.DataBind();
        }

        protected void favProductsGrid_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType != DataControlRowType.DataRow) return;
            bool orderable = Convert.ToBoolean(DataBinder.Eval(e.Row.DataItem, "is_orderable"));
            Label label = (Label)e.Row.FindControl("orderable");
            label.Text = orderable ? "Yes" : "Not available now";
            label.CssClass = orderable ? "status status-Active" : "status status-Rejected";
        }

        // ================= Toggle_Favorite =================

        protected void grid_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            string itemType, idField, nameField;
            bool adding;
            switch (e.CommandName)
            {
                case "RemoveProduct": itemType = "Product"; idField = "product_id"; nameField = "product_name"; adding = false; break;
                case "AddProduct": itemType = "Product"; idField = "product_id"; nameField = "product_name"; adding = true; break;
                case "RemoveBusiness": itemType = "Business"; idField = "business_id"; nameField = "business_name"; adding = false; break;
                default: return;
            }

            GridView grid = (GridView)sender;
            DataKey key = grid.DataKeys[Convert.ToInt32(e.CommandArgument)];
            string name = HttpUtility.HtmlEncode((string)key[nameField]);

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand("Toggle_Favorite", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@customer_id", CustomerId));
            proc.Parameters.Add(new SqlParameter("@item_id", (int)key[idField]));
            proc.Parameters.Add(new SqlParameter("@item_type", itemType));

            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    ShowSuccess(adding ? name + " was added to your favorites." : name + " was removed from your favorites.");
                    break;
                case -1:
                    ShowError(name + " does not exist anymore. The list has been refreshed.");
                    break;
                case -3:
                    ShowError("Only a customer can keep favorites.");
                    return;
                default:
                    ShowCodeError(rc);
                    return;
            }
            BindAll();
        }

        // ================= Helpers =================

        // Runs a Milestone 2 procedure and returns its RETURN code (int.MinValue if the database failed)
        private int RunProcedure(SqlCommand proc)
        {
            SqlParameter returnCode = proc.Parameters.Add("@return", SqlDbType.Int);
            returnCode.Direction = ParameterDirection.ReturnValue;
            try
            {
                proc.Connection.Open();
                proc.ExecuteNonQuery();
            }
            catch (SqlException)
            {
                return int.MinValue;
            }
            finally
            {
                proc.Connection.Close();
            }
            return Convert.ToInt32(returnCode.Value);
        }

        private void ShowCodeError(int code)
        {
            if (code == int.MinValue)
                ShowError("We could not reach the database right now. Please try again in a moment.");
            else
                ShowError("This action could not be completed. Refresh the page and try again.");
        }

        private void ShowSuccess(string text)
        {
            msg.CssClass = "msg msg-success";
            msg.Text = text;
        }

        private void ShowError(string text)
        {
            msg.CssClass = "msg msg-error";
            msg.Text = text;
        }
    }
}
