using System;
using System.Data;
using System.Data.SqlClient;
using System.Web.Configuration;

namespace WebApplication1
{
    public partial class Login : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                // Preselect the user type chosen on the start page
                string type = Request.QueryString["type"];
                if (type == "Customer" || type == "Partner" || type == "Rider" || type == "Admin")
                    usertype.SelectedValue = type;
            }
        }

        protected void login(object sender, EventArgs e)
        {
            // Get the connection string from Web.config
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            string user = username.Text.Trim();
            string pass = password.Text;
            string type = usertype.SelectedValue;

            if (user == "" || pass == "")
            {
                msg.Text = "Please enter your username and password.";
                return;
            }

            int id;
            try
            {
                // Call the login function of this user type
                SqlCommand loginFunc = new SqlCommand("SELECT dbo." + type + "LoginValidation(@username, @password)", conn);
                loginFunc.Parameters.Add(new SqlParameter("@username", user));
                loginFunc.Parameters.Add(new SqlParameter("@password", pass));

                conn.Open();
                bool success = Convert.ToBoolean(loginFunc.ExecuteScalar());

                if (!success)
                {
                    msg.Text = "Wrong username or password. Check that you chose the right account type ("
                               + type + ") and try again.";
                    return;
                }

                // Get the user id
                SqlCommand idFunc = new SqlCommand("SELECT dbo.h_GetUserId(@username)", conn);
                idFunc.Parameters.Add(new SqlParameter("@username", user));
                id = Convert.ToInt32(idFunc.ExecuteScalar());
            }
            catch (SqlException)
            {
                msg.Text = "We could not reach the database right now. Please try again in a moment.";
                return;
            }
            finally
            {
                conn.Close();
            }

            // Remember who is signed in
            Session.Clear();
            Session["user"] = id;
            Session["type"] = type;
            Session["username"] = user;

            Response.Redirect(type + "Home.aspx");
        }
    }
}
