<%@ Page Title="My performance" Language="C#" MasterPageFile="~/Partner.master" AutoEventWireup="true" CodeBehind="PartnerPerformance.aspx.cs" Inherits="WebApplication1.PartnerPerformance" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

    <h1>My business performance</h1>
    <p class="subtitle">Which products bring my revenue, and what do customers think of me?</p>

    <asp:Label ID="msg" runat="server" CssClass="msg msg-error"></asp:Label>

    <asp:Panel ID="noBusinessPanel" runat="server" CssClass="card" Visible="false">
        <p>You have no business yet, so there is nothing to show. Register your business first.</p>
        <p><a class="btn" href="PartnerHome.aspx">Go to my business</a></p>
    </asp:Panel>

    <asp:Panel ID="reportPanel" runat="server">
        <%-- 3.4 d: BusinessSalesReport for a period --%>
        <div class="card">
            <h2>Sales by product</h2>
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
                    <asp:Button ID="showBtn" runat="server" Text="Show sales" CssClass="btn" OnClick="show_Click" />
                </div>
            </div>
            <asp:Label ID="salesSummary" runat="server" CssClass="msg"></asp:Label>
            <asp:GridView ID="salesGrid" runat="server" AutoGenerateColumns="false" CssClass="grid" GridLines="None">
                <Columns>
                    <asp:BoundField DataField="product_name" HeaderText="Product" />
                    <asp:BoundField DataField="units_sold" HeaderText="Units sold" />
                    <asp:BoundField DataField="revenue_per_product" HeaderText="Revenue (EGP)" DataFormatString="{0:N2}" />
                    <asp:BoundField DataField="share" HeaderText="Share of revenue" DataFormatString="{0:0}%" />
                </Columns>
            </asp:GridView>
        </div>

        <%-- 3.4 d: BusinessFeedbackOverview --%>
        <div class="card">
            <h2>What customers think of me</h2>
            <asp:Label ID="feedbackSummary" runat="server" CssClass="msg"></asp:Label>
            <asp:Literal ID="starBars" runat="server"></asp:Literal>
        </div>
    </asp:Panel>

</asp:Content>
