using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Web;
using System.Web.Configuration;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebApplication1
{
    // 3.6 a (business page: details, open now, rating, available products),
    // 3.5 d (add products to my cart with a quantity and a note) and 3.6 b (favorite the business or a product)
    // The session check is in Customer.master (Page_Init), which runs before this page.
    public partial class BusinessPage : System.Web.UI.Page
    {
        private HashSet<int> favoriteProducts = new HashSet<int>();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (IsPostBack) return;

            // The business comes from the link the customer clicked on the browse page
            int businessId;
            if (!int.TryParse(Request.QueryString["id"], out businessId))
            {
                ShowError("Choose a business from the <a href=\"CustomerBrowse.aspx\">browse page</a>.");
                businessPanel.Visible = false;
                return;
            }
            ViewState["bizId"] = businessId;
            ShowBusiness();
        }

        private int BizId { get { return (int)ViewState["bizId"]; } }
        private int CustomerId { get { return (int)Session["user"]; } }

        // ================= Loading =================

        private void ShowBusiness()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            // h_BusinessDetails
            SqlCommand detailsFunc = new SqlCommand("SELECT * FROM dbo.h_BusinessDetails(@business_id)", conn);
            detailsFunc.Parameters.Add(new SqlParameter("@business_id", BizId));
            // h_BusinessProducts
            SqlCommand productsFunc = new SqlCommand(
                "SELECT * FROM dbo.h_BusinessProducts(@business_id) ORDER BY category, product_name", conn);
            productsFunc.Parameters.Add(new SqlParameter("@business_id", BizId));
            // My_Favorites and h_MyFavoriteBusinesses (Team_115.sql): what is already in my favorites
            SqlCommand favProductsFunc = new SqlCommand("SELECT product_id FROM dbo.My_Favorites(@customer_id)", conn);
            favProductsFunc.Parameters.Add(new SqlParameter("@customer_id", CustomerId));
            SqlCommand favBusinessFunc = new SqlCommand(
                "SELECT COUNT(*) FROM dbo.h_MyFavoriteBusinesses(@customer_id) WHERE business_id = @business_id", conn);
            favBusinessFunc.Parameters.Add(new SqlParameter("@customer_id", CustomerId));
            favBusinessFunc.Parameters.Add(new SqlParameter("@business_id", BizId));
            // h_MyActiveCart + h_CartItems: how many items are in my cart
            SqlCommand cartCmd = new SqlCommand(
                "SELECT ISNULL(SUM(quantity), 0) FROM dbo.h_CartItems(dbo.h_MyActiveCart(@customer_id))", conn);
            cartCmd.Parameters.Add(new SqlParameter("@customer_id", CustomerId));

            DataTable details = new DataTable();
            DataTable products = new DataTable();
            DataTable favs = new DataTable();
            bool favBusiness;
            int cartItems;
            try
            {
                new SqlDataAdapter(detailsFunc).Fill(details);
                new SqlDataAdapter(productsFunc).Fill(products);
                new SqlDataAdapter(favProductsFunc).Fill(favs);
                conn.Open();
                favBusiness = (int)favBusinessFunc.ExecuteScalar() > 0;
                cartItems = (int)cartCmd.ExecuteScalar();
            }
            catch (SqlException)
            {
                ShowError("We could not load this business right now. Please refresh the page in a moment.");
                businessPanel.Visible = false;
                return;
            }
            finally
            {
                conn.Close();
            }

            if (details.Rows.Count == 0)
            {
                ShowError("This business does not exist anymore. <a href=\"CustomerBrowse.aspx\">Find another business</a>.");
                businessPanel.Visible = false;
                return;
            }

            DataRow d = details.Rows[0];
            bool open = Convert.ToBoolean(d["is_open_now"]);
            bizName.Text = HttpUtility.HtmlEncode((string)d["business_name"]) + " ";
            openBadge.Text = open ? "Open now" : "Closed now";
            openBadge.CssClass = open ? "status status-Active" : "status status-Rejected";
            bizDescription.Text = HttpUtility.HtmlEncode(d["description"] as string ?? "");
            bizRating.Text = d["avg_rating"] == DBNull.Value
                ? "No ratings yet"
                : ((decimal)d["avg_rating"]).ToString("0.0") + " &#9733; from " + d["number_of_ratings"] + " rating(s)";
            bizZone.Text = HttpUtility.HtmlEncode((string)d["zone_name"]);
            TimeSpan from = (TimeSpan)d["opening_hour"], to = (TimeSpan)d["closing_hour"];
            bizHours.Text = from == to ? "Open 24 hours" : from.ToString(@"hh\:mm") + " - " + to.ToString(@"hh\:mm");
            bizDelivery.Text = "About " + d["expected_delivery_time"] + " minutes";
            bizWebsite.Text = d["link_website"] == DBNull.Value ? "-" : HttpUtility.HtmlEncode((string)d["link_website"]);
            ViewState["bizName"] = (string)d["business_name"];

            string status = (string)d["status"];
            if (status != "Active")
                bizNote.Text = "This business is " + status.ToLower() + " and is not taking orders right now.";
            else if (!open)
                bizNote.Text = "This business is closed now. You can add products to your cart, but you can check out only while it is open.";
            else
                bizNote.Text = "";

            favBusinessBtn.Text = favBusiness ? "♥ In my favorites (remove)" : "♡ Add business to favorites";
            ViewState["favBusiness"] = favBusiness;

            foreach (DataRow f in favs.Rows) favoriteProducts.Add((int)f["product_id"]);
            productsGrid.DataSource = products;
            productsGrid.DataBind();

            cartLine.Text = cartItems == 0
                ? "Your cart is empty."
                : "Your cart: " + cartItems + " item(s) &middot; <a href=\"CustomerCart.aspx\">View cart</a>";
        }

        protected void productsGrid_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType != DataControlRowType.DataRow) return;

            decimal price = (decimal)DataBinder.Eval(e.Row.DataItem, "price");
            decimal final = (decimal)DataBinder.Eval(e.Row.DataItem, "final_price");
            ((Label)e.Row.FindControl("price")).Text = final < price
                ? "<s class=\"muted\">" + price.ToString("N2") + "</s> <b>" + final.ToString("N2") + "</b>"
                : final.ToString("N2");

            bool fav = favoriteProducts.Contains((int)DataBinder.Eval(e.Row.DataItem, "product_id"));
            ((Button)e.Row.FindControl("favBtn")).Text = fav ? "♥ Remove favorite" : "♡ Favorite";
        }

        // ================= Row buttons =================

        protected void productsGrid_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName != "AddToCart" && e.CommandName != "Favorite") return;

            int index = Convert.ToInt32(e.CommandArgument);
            int productId = (int)productsGrid.DataKeys[index]["product_id"];
            string name = (string)productsGrid.DataKeys[index]["product_name"];

            if (e.CommandName == "Favorite")
            {
                bool wasFavorite = ((Button)productsGrid.Rows[index].FindControl("favBtn")).Text.StartsWith("♥");
                ToggleFavorite(productId, "Product", name, wasFavorite);
                return;
            }

            GridViewRow row = productsGrid.Rows[index];
            AddToCart(productId, name, ((TextBox)row.FindControl("qty")).Text.Trim(), ((TextBox)row.FindControl("note")).Text.Trim());
        }

        protected void favBusiness_Click(object sender, EventArgs e)
        {
            ToggleFavorite(BizId, "Business", (string)ViewState["bizName"], (bool)ViewState["favBusiness"]);
        }

        // ================= Create_Cart + Add_To_Cart =================

        private void AddToCart(int productId, string name, string qtyText, string note)
        {
            int quantity;
            if (!int.TryParse(qtyText, out quantity) || quantity < 1)
            {
                ShowError("Enter how many " + HttpUtility.HtmlEncode(name) + " you want (at least 1).");
                return;
            }
            if (quantity > 10)
            {
                ShowError("You can order at most 10 of one product. Lower the quantity.");
                return;
            }

            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);
            bool newCart = false;

            // My active cart (h_MyActiveCart); if I have none, create one for my active address (Create_Cart)
            int? cartId = ActiveCartId();
            if (cartId == null)
            {
                SqlCommand create = new SqlCommand("Create_Cart", conn);
                create.CommandType = CommandType.StoredProcedure;
                create.Parameters.Add(new SqlParameter("@customer_id", CustomerId));
                int crc = RunProcedure(create);
                switch (crc)
                {
                    case 0:
                    case -2:   // a cart of my active address already exists: use it
                        break;
                    case -1:
                        ShowError("You need an active address before you can shop. <a href=\"CustomerAddresses.aspx\">Add an address</a>.");
                        return;
                    case -3:
                        ShowError("Your account is blacklisted, so you cannot shop. Contact support.");
                        return;
                    default:
                        ShowCodeError(crc);
                        return;
                }
                newCart = crc == 0;
                cartId = ActiveCartId();
                if (cartId == null)
                {
                    ShowCodeError(int.MinValue);
                    return;
                }
            }

            SqlCommand proc = new SqlCommand("Add_To_Cart", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@cart_id", cartId.Value));
            proc.Parameters.Add(new SqlParameter("@product_id", productId));
            proc.Parameters.Add(new SqlParameter("@quantity", quantity));
            proc.Parameters.Add(new SqlParameter("@notes", note == "" ? (object)DBNull.Value : note));

            string safe = HttpUtility.HtmlEncode(name);
            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    ShowSuccess((newCart ? "A new cart was created for your active address. " : "")
                              + "Added " + quantity + " &times; " + safe + " to your cart. <a href=\"CustomerCart.aspx\">View cart</a>");
                    break;
                case -1:
                    ShowError(safe + " is not available anymore. The list has been refreshed.");
                    break;
                case -4:
                    ShowError(safe + " cannot be added right now: it is not available, or this business is not taking orders. "
                            + "Choose another product.");
                    break;
                case -5:
                    ShowError("This business does not deliver to your active address. Change your active address or choose another business.");
                    break;
                case -6:
                    int already = QuantityInCart(cartId.Value, productId);
                    ShowError("You can order at most 10 of one product. You already have " + already + " " + safe
                            + " in your cart, so you can add at most " + (10 - already) + " more. Lower the quantity.");
                    return;
                default:
                    ShowCodeError(rc);
                    return;
            }
            ShowBusiness();
        }

        // h_MyActiveCart: the Active cart of my active address (null if none)
        private int? ActiveCartId()
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand cartFunc = new SqlCommand("SELECT dbo.h_MyActiveCart(@customer_id)", conn);
            cartFunc.Parameters.Add(new SqlParameter("@customer_id", CustomerId));
            try
            {
                conn.Open();
                object id = cartFunc.ExecuteScalar();
                return id == null || id == DBNull.Value ? (int?)null : (int)id;
            }
            catch (SqlException)
            {
                return null;
            }
            finally
            {
                conn.Close();
            }
        }

        // h_CartItems: how many of this product are already in my cart
        private int QuantityInCart(int cartId, int productId)
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand itemsFunc = new SqlCommand(
                "SELECT ISNULL(SUM(quantity), 0) FROM dbo.h_CartItems(@cart_id) WHERE product_id = @product_id", conn);
            itemsFunc.Parameters.Add(new SqlParameter("@cart_id", cartId));
            itemsFunc.Parameters.Add(new SqlParameter("@product_id", productId));
            try
            {
                conn.Open();
                return (int)itemsFunc.ExecuteScalar();
            }
            catch (SqlException)
            {
                return 0;
            }
            finally
            {
                conn.Close();
            }
        }

        // ================= Toggle_Favorite =================

        private void ToggleFavorite(int itemId, string itemType, string name, bool wasFavorite)
        {
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            SqlCommand proc = new SqlCommand("Toggle_Favorite", conn);
            proc.CommandType = CommandType.StoredProcedure;
            proc.Parameters.Add(new SqlParameter("@customer_id", CustomerId));
            proc.Parameters.Add(new SqlParameter("@item_id", itemId));
            proc.Parameters.Add(new SqlParameter("@item_type", itemType));

            string safe = HttpUtility.HtmlEncode(name);
            int rc = RunProcedure(proc);
            switch (rc)
            {
                case 0:
                    ShowSuccess(wasFavorite
                        ? safe + " was removed from your favorites."
                        : safe + " was added to your favorites. <a href=\"CustomerFavorites.aspx\">See my favorites</a>");
                    break;
                case -1:
                    ShowError(safe + " does not exist anymore.");
                    break;
                case -3:
                    ShowError("Only a customer can keep favorites.");
                    return;
                default:
                    ShowCodeError(rc);
                    return;
            }
            ShowBusiness();
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
