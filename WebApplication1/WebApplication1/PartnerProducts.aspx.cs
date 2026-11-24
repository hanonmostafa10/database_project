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
    // 3.4 c: add or edit a product, deactivate or reactivate it, set or remove its discount
    // The session check is in Partner.master (Page_Init), which runs before this page.
    public partial class PartnerProducts : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
                BindProducts();
        }

        // ================= Loading =================

        // h_MyBusiness: my business id and status (null if I have none)
        private DataRow ReadMyBusiness()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand businessFunc = new SqlCommand(
                "SELECT business_id, business_name, status FROM dbo.h_MyBusiness(@partner_id)", conn);
            businessFunc.Parameters.Add(new SqlParameter("@partner_id", (int)Session["user"]));

            DataTable rows = new DataTable();
            new SqlDataAdapter(businessFunc).Fill(rows);
            return rows.Rows.Count == 0 ? null : rows.Rows[0];
        }

        private void BindProducts()
        {
            DataRow biz;
            DataTable products = new DataTable();
            try
            {
                biz = ReadMyBusiness();
                if (biz != null)
                {
                    string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
                    SqlConnection conn = new SqlConnection(connStr);

                    // h_MyProducts: all products of my business, available or not
                    SqlCommand productsFunc = new SqlCommand(
                        "SELECT * FROM dbo.h_MyProducts(@partner_id) ORDER BY is_available DESC, product_name", conn);
                    productsFunc.Parameters.Add(new SqlParameter("@partner_id", (int)Session["user"]));
                    new SqlDataAdapter(productsFunc).Fill(products);
                }
            }
            catch (SqlException)
            {
                ShowError("We could not load your products right now. Please refresh the page in a moment.");
                productsPanel.Visible = false;
                return;
            }

            // Products need a business that is not rejected
            if (biz == null || (string)biz["status"] == "Rejected")
            {
                productsPanel.Visible = false;
                noBusinessPanel.Visible = true;
                noBusinessText.Text = biz == null
                    ? "You have no business yet. Register your business first, then add its products here."
                    : "Your business was rejected. Register it again first, then manage its products here.";
                return;
            }

            productsPanel.Visible = true;
            noBusinessPanel.Visible = false;
            bool suspended = (string)biz["status"] == "Suspended";
            ViewState["suspended"] = suspended;
            suspendedNote.Text = suspended
                ? "Your business is suspended, so all your products are hidden and you cannot add, edit or reactivate products "
                  + "until an admin reinstates it. You can still change discounts."
                : "";
            addBtn.Visible = !suspended;

            productsGrid.DataSource = products;
            productsGrid.DataBind();
        }

        protected void productsGrid_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType != DataControlRowType.DataRow) return;

            bool available = (bool)DataBinder.Eval(e.Row.DataItem, "is_available");
            bool suspended = ViewState["suspended"] != null && (bool)ViewState["suspended"];

            Label status = (Label)e.Row.FindControl("availability");
            status.Text = available ? "Available" : "Hidden";
            status.CssClass = available ? "status status-Active" : "status status-Rejected";

            Button toggle = (Button)e.Row.FindControl("toggleBtn");
            toggle.Text = available ? "Deactivate" : "Reactivate";
            toggle.CssClass = available ? "btn btn-sm btn-danger" : "btn btn-sm";
            // A suspended business cannot reactivate or edit products
            toggle.Visible = available || !suspended;
            e.Row.FindControl("editBtn").Visible = !suspended;
        }

        // ================= Row buttons =================

        protected void productsGrid_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName != "EditProduct" && e.CommandName != "Discount" && e.CommandName != "Toggle") return;

            DataKey key = productsGrid.DataKeys[Convert.ToInt32(e.CommandArgument)];
            int productId = (int)key["product_id"];
            string name = (string)key["product_name"];
            msg.Text = "";

            if (e.CommandName == "EditProduct")
            {
                ViewState["editId"] = productId;
                productFormTitle.Text = "Edit " + HttpUtility.HtmlEncode(name);
                pName.Text = name;
                pDescription.Text = key["description"] as string ?? "";
                pCategory.Text = (string)key["category"];
                pPrice.Text = ((decimal)key["price"]).ToString("0.00", CultureInfo.InvariantCulture);
                pAvailable.Checked = (bool)key["is_available"];
                productForm.Visible = true;
                discountForm.Visible = false;
            }
            else if (e.CommandName == "Discount")
            {
                decimal price = (decimal)key["price"];
                ViewState["discountId"] = productId;
                ViewState["discountName"] = name;
                ViewState["discountPrice"] = price;
                discountFormTitle.Text = "Discount on " + HttpUtility.HtmlEncode(name);
                discountHint.Text = "The price is " + price.ToString("N2") + " EGP. The discount can be at most half of it ("
                                  + (price / 2).ToString("N2") + " EGP).";
                dAmount.Text = ((decimal)key["discount_amount"]).ToString("0.00", CultureInfo.InvariantCulture);
                discountForm.Visible = true;
                productForm.Visible = false;
            }
            else
            {
                Toggle(productId, name, !(bool)key["is_available"]);
            }
        }

        protected void add_Click(object sender, EventArgs e)
        {
            ViewState["editId"] = null;
            productFormTitle.Text = "Add a product";
            pName.Text = pDescription.Text = pCategory.Text = pPrice.Text = "";
            pAvailable.Checked = true;
            productForm.Visible = true;
            discountForm.Visible = false;
            msg.Text = "";
        }

        protected void cancelForms_Click(object sender, EventArgs e)
        {
            productForm.Visible = false;
            discountForm.Visible = false;
            msg.Text = "";
        }

        // ================= Upsert_Product =================

        protected void saveProduct_Click(object sender, EventArgs e)
        {
            string name = pName.Text.Trim();
            string category = pCategory.Text.Trim();
            string description = pDescription.Text.Trim();
            decimal price;
            bool editing = ViewState["editId"] != null;

            if (name == "" || category == "")
            {
                ShowError("Please enter the product name and its category.");
                return;
            }
            if (!decimal.TryParse(pPrice.Text.Trim(), NumberStyles.Number, CultureInfo.InvariantCulture, out price)
                || price <= 0 || price > 99999999.99m)
            {
                ShowError("Please enter a price greater than 0 EGP.");
                return;
            }

            DataRow biz;
            try { biz = ReadMyBusiness(); }
            catch (SqlException) { ShowError("We could not reach the database right now. Please try again in a moment."); return; }
            if (biz == null)
            {
                ShowError("You have no business yet. Register your business first.");
                return;
            }

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand("Upsert_Product", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@business_id", (int)biz["business_id"]));
            proc.Parameters.Add(new SqlParameter("@product_id", editing ? ViewState["editId"] : DBNull.Value));
            proc.Parameters.Add(new SqlParameter("@name", name));
            proc.Parameters.Add(new SqlParameter("@description", description == "" ? (object)DBNull.Value : description));
            proc.Parameters.Add(new SqlParameter("@category", category));
            proc.Parameters.Add(new SqlParameter("@price", price));
            proc.Parameters.Add(new SqlParameter("@is_available", pAvailable.Checked));

            string safeName = HttpUtility.HtmlEncode(name);
            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    ShowSuccess(editing
                        ? safeName + " was saved."
                        : safeName + " was added" + (pAvailable.Checked ? " and customers can order it." : " as hidden. Reactivate it when it is ready."));
                    productForm.Visible = false;
                    ViewState["editId"] = null;
                    BindProducts();
                    break;
                case -1:
                    ShowError(editing
                        ? "The product could not be saved. Name, category and a price above 0 are required, and the price must be at "
                          + "least twice its current discount. Lower or remove the discount first, or enter a higher price."
                        : "Please enter the product name, its category and a price above 0 EGP.");
                    break;
                case -3:
                    ShowError("This product belongs to another business, so you cannot edit it.");
                    break;
                case -4:
                    ShowError("Your business is suspended, so you cannot add or edit products until an admin reinstates it.");
                    break;
                default:
                    ShowCodeError(rc);
                    break;
            }
        }

        // ================= Toggle_Product_Status =================

        private void Toggle(int productId, string name, bool makeAvailable)
        {
            // Toggle_Product_Status does not check the owner, so check that this product is mine first
            if (!OwnsProduct(productId)) return;

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand("Toggle_Product_Status", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@product_id", productId));
            proc.Parameters.Add(new SqlParameter("@is_available", makeAvailable));

            string safeName = HttpUtility.HtmlEncode(name);
            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    ShowSuccess(makeAvailable ? safeName + " is available again and customers can order it."
                                              : safeName + " is now hidden from customers. Reactivate it any time.");
                    break;
                case -1:
                    ShowError("This product does not exist anymore. The list has been refreshed.");
                    break;
                case -4:
                    ShowError("Your business is suspended, so you cannot make products available until an admin reinstates it.");
                    break;
                default:
                    ShowCodeError(rc);
                    return;
            }
            productForm.Visible = false;
            discountForm.Visible = false;
            BindProducts();
        }

        // ================= Set_Product_Promotion =================

        protected void saveDiscount_Click(object sender, EventArgs e)
        {
            decimal amount;
            if (!decimal.TryParse(dAmount.Text.Trim(), NumberStyles.Number, CultureInfo.InvariantCulture, out amount)
                || amount < 0 || amount > 99999999.99m)
            {
                ShowError("Please enter the discount in EGP, 0 or more.");
                return;
            }
            decimal price = (decimal)ViewState["discountPrice"];
            if (amount > price / 2)
            {
                ShowError("The discount must be between 0 and 50% of the price, so at most " + (price / 2).ToString("N2")
                        + " EGP. Enter a smaller amount.");
                return;
            }
            SetDiscount(amount);
        }

        protected void removeDiscount_Click(object sender, EventArgs e)
        {
            SetDiscount(0);
        }

        private void SetDiscount(decimal amount)
        {
            if (ViewState["discountId"] == null) return;
            int productId = (int)ViewState["discountId"];

            // Set_Product_Promotion does not check the owner, so check that this product is mine first
            if (!OwnsProduct(productId)) return;

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand("Set_Product_Promotion", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@product_id", productId));
            proc.Parameters.Add(new SqlParameter("@discount_amount", amount));

            string safeName = HttpUtility.HtmlEncode((string)ViewState["discountName"]);
            decimal price = (decimal)ViewState["discountPrice"];
            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    if (amount == 0)
                        ShowSuccess("The discount on " + safeName + " was removed. Customers pay the full price of " + price.ToString("N2") + " EGP.");
                    else
                        ShowSuccess(safeName + " now costs " + (price - amount).ToString("N2") + " EGP (" + amount.ToString("N2") + " EGP off).");
                    discountForm.Visible = false;
                    BindProducts();
                    break;
                case -1:
                    ShowError("The discount must be between 0 and 50% of the price, so at most " + (price / 2).ToString("N2")
                            + " EGP. Enter a smaller amount.");
                    break;
                default:
                    ShowCodeError(rc);
                    break;
            }
        }

        // ================= Helpers =================

        // Is this product one of mine (h_MyProducts)? Shows a message if not.
        private bool OwnsProduct(int productId)
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand mineFunc = new SqlCommand(
                "SELECT COUNT(*) FROM dbo.h_MyProducts(@partner_id) WHERE product_id = @product_id", conn);
            mineFunc.Parameters.Add(new SqlParameter("@partner_id", (int)Session["user"]));
            mineFunc.Parameters.Add(new SqlParameter("@product_id", productId));

            try
            {
                conn.Open();
                if ((int)mineFunc.ExecuteScalar() > 0) return true;
            }
            catch (SqlException)
            {
                ShowError("We could not reach the database right now. Please try again in a moment.");
                return false;
            }
            finally
            {
                conn.Close();
            }
            ShowError("This product is not one of your products anymore. The list has been refreshed.");
            BindProducts();
            return false;
        }

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
