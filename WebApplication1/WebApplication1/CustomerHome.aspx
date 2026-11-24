<%@ Page Title="Home" Language="C#" MasterPageFile="~/Customer.master" AutoEventWireup="true" CodeBehind="CustomerHome.aspx.cs" Inherits="WebApplication1.CustomerHome" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

    <asp:Label ID="msg" runat="server" CssClass="msg msg-error"></asp:Label>

    <%-- 3.5 a: my name, my active address and my wallet balance --%>
    <div class="card">
        <h1>Hello, <asp:Label ID="customerName" runat="server"></asp:Label></h1>
        <div class="stats">
            <div class="stat">
                <div class="stat-value"><asp:Label ID="wallet" runat="server"></asp:Label></div>
                <div class="stat-label">Wallet balance</div>
            </div>
            <div class="stat">
                <div class="stat-value stat-text"><asp:Label ID="activeAddress" runat="server"></asp:Label></div>
                <div class="stat-label"><asp:Label ID="activeZone" runat="server"></asp:Label></div>
            </div>
            <div class="stat">
                <div class="stat-value"><asp:Label ID="onTheWay" runat="server"></asp:Label></div>
                <div class="stat-label">Orders on the way</div>
            </div>
        </div>
        <asp:Label ID="addressHint" runat="server" CssClass="msg msg-warning"></asp:Label>

        <div class="quick-links">
            <a href="CustomerBrowse.aspx"><b>Browse</b><span>Search businesses or browse by category</span></a>
            <a href="CustomerCart.aspx"><b>My cart</b><span>Products in my cart and checkout</span></a>
            <a href="CustomerOrders.aspx"><b>My orders</b><span>Track, cancel, reorder, give feedback</span></a>
            <a href="CustomerFavorites.aspx"><b>Favorites</b><span>My favorites and recommendations</span></a>
            <a href="CustomerAddresses.aspx"><b>My addresses</b><span>Add, edit and choose my active address</span></a>
            <a href="CustomerCards.aspx"><b>My cards</b><span>Save a card for checkout</span></a>
        </div>
    </div>

</asp:Content>
