<%@ Page Title="My performance" Language="C#" MasterPageFile="~/Rider.master" AutoEventWireup="true" CodeBehind="RiderPerformance.aspx.cs" Inherits="WebApplication1.RiderPerformance" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

    <h1>My performance</h1>
    <p class="subtitle">How much did I earn in a period, how fast am I, and how do customers rate me?</p>

    <asp:Label ID="msg" runat="server" CssClass="msg msg-error"></asp:Label>

    <div class="card">
        <div class="row">
            <div class="field">
                <label>From</label>
                <asp:TextBox ID="fromDate" runat="server" TextMode="Date"></asp:TextBox>
            </div>
            <div class="field">
                <label>To</label>
                <asp:TextBox ID="toDate" runat="server" TextMode="Date"></asp:TextBox>
            </div>
            <div class="field field-button">
                <asp:Button ID="showBtn" runat="server" Text="Show my performance" CssClass="btn" OnClick="show_Click" />
            </div>
        </div>
        <asp:Label ID="periodMsg" runat="server" CssClass="msg"></asp:Label>

        <%-- My_Earnings + speed from My_Delivery_History --%>
        <asp:Panel ID="periodPanel" runat="server">
            <div class="stats">
                <div class="stat">
                    <div class="stat-value"><asp:Label ID="statEarnings" runat="server"></asp:Label></div>
                    <div class="stat-label">My earnings (80% of delivery fees)</div>
                </div>
                <div class="stat">
                    <div class="stat-value"><asp:Label ID="statDeliveries" runat="server"></asp:Label></div>
                    <div class="stat-label">Deliveries completed</div>
                </div>
                <div class="stat">
                    <div class="stat-value"><asp:Label ID="statFees" runat="server"></asp:Label></div>
                    <div class="stat-label">Delivery fees collected</div>
                </div>
                <div class="stat">
                    <div class="stat-value"><asp:Label ID="statSpeed" runat="server"></asp:Label></div>
                    <div class="stat-label"><asp:Label ID="statSpeedLabel" runat="server"></asp:Label></div>
                </div>
            </div>
            <asp:Label ID="speedMsg" runat="server" CssClass="msg"></asp:Label>

            <h3>My deliveries in this period</h3>
            <asp:GridView ID="historyGrid" runat="server" AutoGenerateColumns="false" CssClass="grid" GridLines="None"
                EmptyDataText="No finished or cancelled deliveries in this period.">
                <Columns>
                    <asp:BoundField DataField="order_id" HeaderText="Order #" />
                    <asp:BoundField DataField="business_name" HeaderText="Business" />
                    <asp:BoundField DataField="status" HeaderText="Result" />
                    <asp:BoundField DataField="assigned_at" HeaderText="Assigned" DataFormatString="{0:d MMM HH:mm}" />
                    <asp:BoundField DataField="picked_up_at" HeaderText="Picked up" DataFormatString="{0:d MMM HH:mm}" NullDisplayText="&ndash;" HtmlEncode="false" />
                    <asp:BoundField DataField="delivered_at" HeaderText="Delivered" DataFormatString="{0:d MMM HH:mm}" NullDisplayText="&ndash;" HtmlEncode="false" />
                    <asp:BoundField DataField="tracking_time" HeaderText="On the road (min)" NullDisplayText="&ndash;" HtmlEncode="false" />
                </Columns>
            </asp:GridView>
        </asp:Panel>
    </div>

    <%-- My_Rating_Summary (all time) --%>
    <div class="card">
        <h2>How customers rate me</h2>
        <asp:Label ID="ratingMsg" runat="server" CssClass="msg"></asp:Label>
        <asp:Literal ID="starBars" runat="server"></asp:Literal>
    </div>

</asp:Content>
