<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="WebApplication1.Login" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Login</title>
</head>
<body>
    <form id="form1" runat="server">
        <div>
            <asp:Label ID="Label1" runat="server" Text="Please Log In"></asp:Label>
            <br /><br />
            User type:
            <asp:DropDownList ID="usertype" runat="server">
                <asp:ListItem Value="Customer">Customer</asp:ListItem>
                <asp:ListItem Value="Partner">Partner</asp:ListItem>
                <asp:ListItem Value="Rider">Rider</asp:ListItem>
                <asp:ListItem Value="Admin">Admin</asp:ListItem>
            </asp:DropDownList>
            <br />
            Username:
            <asp:TextBox ID="username" runat="server"></asp:TextBox>
            <br />
            Password:
            <asp:TextBox ID="password" runat="server" TextMode="Password"></asp:TextBox>
            <br />
            <asp:Button ID="signin" runat="server" Text="Log in" OnClick="login" />
            <br />
            <asp:Label ID="msg" runat="server" ForeColor="Red"></asp:Label>
        </div>
    </form>
</body>
</html>