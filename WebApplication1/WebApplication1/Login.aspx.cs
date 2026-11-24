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
        }

        protected void login(object sender, EventArgs e)
        {
            // Get the connection string from Web.config
            string connStr = WebConfigurationManager.ConnectionStrings["DeliveryDB"].ToString();
            SqlConnection conn = new SqlConnection(connStr);

            string user = username.Text;
            string pass = password.Text;
            string type = usertype.SelectedValue;

            if (user == "" || pass == "")
            {
                msg.Text = "Please enter your username and password.";
                return;
            }

            // Call the login function of this user type
            SqlCommand loginFunc = new SqlCommand("SELECT dbo." + type + "LoginValidation(@username, @password)", conn);
            loginFunc.Parameters.Add(new SqlParameter("@username", user));
            loginFunc.Parameters.Add(new SqlParameter("@password", pass));

            conn.Open();
            bool success = Convert.ToBoolean(loginFunc.ExecuteScalar());

            if (!success)
            {
                conn.Close();
                msg.Text = "Wrong username or password";
                return;
            }

            // Get the user id
            SqlCommand idFunc = new SqlCommand("SELECT dbo.h_GetUserId(@username)", conn);
            idFunc.Parameters.Add(new SqlParameter("@username", user));
            int id = Convert.ToInt32(idFunc.ExecuteScalar());
            conn.Close();

            // Remember who is signed in
            Session["user"] = id;
            Session["type"] = type;

            Response.Redirect(type + "Home.aspx");
        }
    }
}