<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="WebApplication1.Default" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Local Delivery Marketplace</title>
    <link href="Content/site.css" rel="stylesheet" />
</head>
<body>
    <form id="form1" runat="server">
        <div class="topbar">
            <a class="brand" href="Default.aspx">Local Delivery Marketplace</a>
        </div>

        <div class="container">
            <h1>Welcome</h1>
            <p class="subtitle">Order from local restaurants and pharmacies, run your business, or deliver with us.</p>

            <div class="card-grid">
                <div class="card">
                    <h2>Customer</h2>
                    <p>Browse local businesses, fill your cart and track your orders.</p>
                    <div class="btn-row">
                        <a class="btn" href="Login.aspx?type=Customer">Log in</a>
                        <a class="btn btn-secondary" href="Register.aspx?type=Customer">Register</a>
                    </div>
                </div>

                <div class="card">
                    <h2>Partner</h2>
                    <p>Register your business, manage your products and see your sales.</p>
                    <div class="btn-row">
                        <a class="btn" href="Login.aspx?type=Partner">Log in</a>
                        <a class="btn btn-secondary" href="Register.aspx?type=Partner">Register</a>
                    </div>
                </div>

                <div class="card">
                    <h2>Rider</h2>
                    <p>Pick up and deliver orders in your zone and follow your earnings.</p>
                    <div class="btn-row">
                        <a class="btn" href="Login.aspx?type=Rider">Log in</a>
                        <a class="btn btn-secondary" href="Register.aspx?type=Rider">Register</a>
                    </div>
                </div>

                <div class="card">
                    <h2>Admin</h2>
                    <p>Manage businesses, customers, zones and platform reports.</p>
                    <div class="btn-row">
                        <a class="btn" href="Login.aspx?type=Admin">Log in</a>
                    </div>
                </div>
            </div>
        </div>
    </form>
</body>
</html>
