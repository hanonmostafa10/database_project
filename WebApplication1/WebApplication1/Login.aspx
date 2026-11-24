<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="WebApplication1.Login" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Log in</title>
    <link href="Content/site.css" rel="stylesheet" />
</head>
<body>
    <form id="form1" runat="server">
        <div class="topbar">
            <a class="brand" href="Default.aspx">Local Delivery Marketplace</a>
        </div>

        <div class="container narrow">
            <div class="card">
                <h1>Log in</h1>
                <p class="subtitle">Choose your account type and enter your username and password.</p>

                <div class="field">
                    <label for="usertype">I am a</label>
                    <asp:DropDownList ID="usertype" runat="server">
                        <asp:ListItem Value="Customer">Customer</asp:ListItem>
                        <asp:ListItem Value="Partner">Partner</asp:ListItem>
                        <asp:ListItem Value="Rider">Rider</asp:ListItem>
                        <asp:ListItem Value="Admin">Admin</asp:ListItem>
                    </asp:DropDownList>
                </div>
                <div class="field">
                    <label for="username">Username</label>
                    <asp:TextBox ID="username" runat="server" MaxLength="30"></asp:TextBox>
                </div>
                <div class="field">
                    <label for="password">Password</label>
                    <asp:TextBox ID="password" runat="server" TextMode="Password" MaxLength="30"></asp:TextBox>
                </div>

                <asp:Button ID="signin" runat="server" Text="Log in" OnClick="login" CssClass="btn btn-full" />
                <asp:Label ID="msg" runat="server" CssClass="msg msg-error"></asp:Label>

                <div class="links">
                    No account yet? <a href="Register.aspx">Register as a customer, partner or rider</a><br />
                    <a href="Default.aspx">Back to the start page</a>
                </div>
            </div>
        </div>
    </form>
</body>
</html>
