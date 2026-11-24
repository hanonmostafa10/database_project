<%@ Page Title="Admin dashboard" Language="C#" MasterPageFile="~/Admin.master" AutoEventWireup="true" CodeBehind="AdminHome.aspx.cs" Inherits="WebApplication1.AdminHome" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

    <asp:Label ID="msg" runat="server" CssClass="msg msg-error"></asp:Label>

    <%-- 3.2 a: my name, my role and, for a Zone Admin, my zone --%>
    <div class="card">
        <h1><asp:Label ID="welcome" runat="server"></asp:Label></h1>
        <asp:Label ID="roleBadge" runat="server" CssClass="badge"></asp:Label>
        <asp:Label ID="zoneLine" runat="server"></asp:Label>

        <div class="quick-links">
            <a href="AdminBusinesses.aspx"><b>Businesses</b><span>Approve, suspend, reinstate</span></a>
            <a href="AdminCustomers.aspx"><b>Customers &amp; vouchers</b><span>Issue vouchers, blacklist</span></a>
            <a href="AdminZones.aspx"><b>Zones</b><span>Zones and delivery fees</span></a>
            <a href="AdminInsights.aspx#zones"><b>Zone comparison</b><span>Strongest and weakest zones</span></a>
            <a href="AdminInsights.aspx#revenue"><b>Revenue of a day</b><span>Where the money came from</span></a>
            <a href="AdminInsights.aspx#riders"><b>Riders</b><span>Best riders and who falls behind</span></a>
            <a href="AdminInsights.aspx#market"><b>Market</b><span>Best sellers, loved and avoided</span></a>
            <asp:HyperLink ID="quickAccounts" runat="server" NavigateUrl="~/AdminAccounts.aspx"><b>Admin accounts</b><span>Create admins, assign zones</span></asp:HyperLink>
        </div>
    </div>

    <%-- 3.3 a: is the platform healthy today, and is anything wrong? --%>
    <div class="card">
        <h2>Platform today</h2>
        <asp:Label ID="healthStatus" runat="server" CssClass="msg"></asp:Label>

        <div class="stats">
            <asp:Panel ID="tileBusinesses" runat="server" CssClass="stat">
                <div class="stat-value"><asp:Label ID="statBusinesses" runat="server"></asp:Label></div>
                <div class="stat-label">Active businesses</div>
            </asp:Panel>
            <asp:Panel ID="tileRiders" runat="server" CssClass="stat">
                <div class="stat-value"><asp:Label ID="statRiders" runat="server"></asp:Label></div>
                <div class="stat-label">Riders available now</div>
            </asp:Panel>
            <asp:Panel ID="tileOrders" runat="server" CssClass="stat">
                <div class="stat-value"><asp:Label ID="statOrders" runat="server"></asp:Label></div>
                <div class="stat-label">Orders today</div>
            </asp:Panel>
            <asp:Panel ID="tileAvgTime" runat="server" CssClass="stat">
                <div class="stat-value"><asp:Label ID="statAvgTime" runat="server"></asp:Label></div>
                <div class="stat-label"><asp:Label ID="statAvgTimeLabel" runat="server"></asp:Label></div>
            </asp:Panel>
            <asp:Panel ID="tileLowRatings" runat="server" CssClass="stat">
                <div class="stat-value"><asp:Label ID="statLowRatings" runat="server"></asp:Label></div>
                <div class="stat-label">Ratings of 2 stars or less today</div>
            </asp:Panel>
        </div>

        <asp:BulletedList ID="issuesList" runat="server" CssClass="issues"></asp:BulletedList>
    </div>

    <%-- 3.3 a: orders whose totals do not match must not be missed --%>
    <div class="card">
        <h2>Order totals check</h2>
        <asp:Label ID="totalsStatus" runat="server" CssClass="msg"></asp:Label>
        <asp:GridView ID="mismatchGrid" runat="server" AutoGenerateColumns="false" CssClass="grid" GridLines="None">
            <Columns>
                <asp:BoundField DataField="order_id" HeaderText="Order #" />
                <asp:BoundField DataField="expected_total" HeaderText="Expected total (EGP)" DataFormatString="{0:N2}" />
                <asp:BoundField DataField="order_total" HeaderText="Order total (EGP)" DataFormatString="{0:N2}" />
                <asp:BoundField DataField="payment_amount" HeaderText="Paid (EGP)" DataFormatString="{0:N2}" NullDisplayText="No payment" />
                <asp:BoundField DataField="problem" HeaderText="Problem" />
            </Columns>
        </asp:GridView>
    </div>

</asp:Content>
