<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Register.aspx.cs" Inherits="WebApplication1.Register" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Register</title>
    <link href="Content/site.css" rel="stylesheet" />
</head>
<body>
    <form id="form1" runat="server">
        <div class="topbar">
            <a class="brand" href="Default.aspx">Local Delivery Marketplace</a>
        </div>

        <div class="container narrow">
            <div class="card">
                <h1>Create an account</h1>
                <p class="subtitle">Fields marked optional can be left empty.</p>

                <div class="field">
                    <label for="regtype">I want to register as a</label>
                    <asp:DropDownList ID="regtype" runat="server" AutoPostBack="true" OnSelectedIndexChanged="regtype_Changed">
                        <asp:ListItem Value="Customer">Customer</asp:ListItem>
                        <asp:ListItem Value="Partner">Partner (business owner)</asp:ListItem>
                        <asp:ListItem Value="Rider">Rider</asp:ListItem>
                    </asp:DropDownList>
                </div>

                <div class="row">
                    <div class="field">
                        <label for="firstName">First name</label>
                        <asp:TextBox ID="firstName" runat="server" MaxLength="30"></asp:TextBox>
                    </div>
                    <div class="field">
                        <label for="middleName">Middle name <span class="hint">(optional)</span></label>
                        <asp:TextBox ID="middleName" runat="server" MaxLength="30"></asp:TextBox>
                    </div>
                </div>
                <div class="field">
                    <label for="lastName">Last name</label>
                    <asp:TextBox ID="lastName" runat="server" MaxLength="30"></asp:TextBox>
                </div>
                <div class="field">
                    <label for="regUsername">Username</label>
                    <asp:TextBox ID="regUsername" runat="server" MaxLength="30"></asp:TextBox>
                </div>
                <div class="row">
                    <div class="field">
                        <label for="regPassword">Password</label>
                        <asp:TextBox ID="regPassword" runat="server" TextMode="Password" MaxLength="30"></asp:TextBox>
                    </div>
                    <div class="field">
                        <label for="confirmPassword">Repeat password</label>
                        <asp:TextBox ID="confirmPassword" runat="server" TextMode="Password" MaxLength="30"></asp:TextBox>
                    </div>
                </div>
                <div class="field">
                    <label for="email">Email</label>
                    <asp:TextBox ID="email" runat="server" TextMode="Email" MaxLength="100"></asp:TextBox>
                </div>
                <div class="row">
                    <div class="field">
                        <label for="phone">Phone <span class="hint">(optional, 11 digits)</span></label>
                        <asp:TextBox ID="phone" runat="server" MaxLength="11" placeholder="01012345678"></asp:TextBox>
                    </div>
                    <div class="field">
                        <label for="dob">Date of birth <span class="hint">(optional)</span></label>
                        <asp:TextBox ID="dob" runat="server" TextMode="Date"></asp:TextBox>
                    </div>
                </div>

                <%-- Extra details that only a rider gives --%>
                <asp:Panel ID="riderPanel" runat="server" Visible="false">
                    <h2>Rider details</h2>
                    <div class="row">
                        <div class="field">
                            <label for="vehicleType">Vehicle</label>
                            <asp:DropDownList ID="vehicleType" runat="server">
                                <asp:ListItem Value="Motorcycle">Motorcycle</asp:ListItem>
                                <asp:ListItem Value="Bicycle">Bicycle</asp:ListItem>
                                <asp:ListItem Value="Car">Car</asp:ListItem>
                            </asp:DropDownList>
                        </div>
                        <div class="field">
                            <label for="zone">Zone I deliver in</label>
                            <asp:DropDownList ID="zone" runat="server"></asp:DropDownList>
                        </div>
                    </div>
                    <div class="row">
                        <div class="field">
                            <label for="plateNo">Plate number</label>
                            <asp:TextBox ID="plateNo" runat="server" MaxLength="15"></asp:TextBox>
                        </div>
                        <div class="field">
                            <label for="licenseNo">License number</label>
                            <asp:TextBox ID="licenseNo" runat="server" MaxLength="20"></asp:TextBox>
                        </div>
                    </div>
                </asp:Panel>

                <asp:Button ID="registerBtn" runat="server" Text="Create account" OnClick="register" CssClass="btn btn-full" />
                <asp:Label ID="msg" runat="server" CssClass="msg msg-error"></asp:Label>

                <div class="links">
                    Already have an account? <a href="Login.aspx">Log in</a><br />
                    <a href="Default.aspx">Back to the start page</a>
                </div>
            </div>
        </div>
    </form>
</body>
</html>
