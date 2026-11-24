<%@ Page Title="Insights" Language="C#" MasterPageFile="~/Admin.master" AutoEventWireup="true" CodeBehind="AdminInsights.aspx.cs" Inherits="WebApplication1.AdminInsights" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

    <h1>Platform insights</h1>
    <p class="subtitle">
        <a href="#zones">Zone comparison</a> &middot; <a href="#revenue">Revenue of a day</a> &middot;
        <a href="#riders">Riders</a> &middot; <a href="#market">Market</a>
    </p>

    <asp:Label ID="msg" runat="server" CssClass="msg msg-error"></asp:Label>

    <%-- 3.3 c: which zone is strongest and which needs help? --%>
    <div class="card" id="zones">
        <h2>Zone comparison</h2>
        <p class="muted">Which zone is strongest and which needs help? Orders, order totals and commission are for the dates you choose;
            businesses are the active ones now, and deliveries are all time.</p>
        <div class="row">
            <div class="field">
                <label>From</label>
                <asp:TextBox ID="zoneFrom" runat="server" TextMode="Date"></asp:TextBox>
            </div>
            <div class="field">
                <label>To</label>
                <asp:TextBox ID="zoneTo" runat="server" TextMode="Date"></asp:TextBox>
            </div>
            <div class="field field-button">
                <asp:Button ID="zoneBtn" runat="server" Text="Compare zones" CssClass="btn" OnClick="zoneBtn_Click" />
            </div>
        </div>
        <asp:Label ID="zoneSummary" runat="server" CssClass="msg"></asp:Label>
        <asp:GridView ID="zoneGrid" runat="server" AutoGenerateColumns="false" CssClass="grid" GridLines="None">
            <Columns>
                <asp:BoundField DataField="zone_name" HeaderText="Zone" />
                <asp:BoundField DataField="business_count" HeaderText="Active businesses" />
                <asp:BoundField DataField="number_of_orders" HeaderText="Orders" />
                <asp:BoundField DataField="avg_order_total" HeaderText="Avg order (EGP)" DataFormatString="{0:N2}" NullDisplayText="&ndash;" HtmlEncode="false" />
                <asp:BoundField DataField="platform_commission" HeaderText="Commission (EGP)" DataFormatString="{0:N2}" />
                <asp:BoundField DataField="delivery_count" HeaderText="Deliveries (all time)" />
                <asp:BoundField DataField="avg_tracking_time" HeaderText="Avg delivery time (min)" DataFormatString="{0:0.#}" NullDisplayText="&ndash;" HtmlEncode="false" />
            </Columns>
        </asp:GridView>
    </div>

    <%-- 3.3 d: where did the money of this day come from, and how much did the platform earn? --%>
    <div class="card" id="revenue">
        <h2>Revenue of a day</h2>
        <p class="muted">Where did the money of this day come from, and how much did the platform earn?</p>
        <div class="row">
            <div class="field">
                <label>Day</label>
                <asp:TextBox ID="revenueDate" runat="server" TextMode="Date"></asp:TextBox>
            </div>
            <div class="field field-button">
                <asp:Button ID="revenueBtn" runat="server" Text="Show revenue" CssClass="btn" OnClick="revenueBtn_Click" />
            </div>
        </div>
        <asp:Label ID="revenueSummary" runat="server" CssClass="msg"></asp:Label>
        <asp:GridView ID="revenueGrid" runat="server" AutoGenerateColumns="false" CssClass="grid" GridLines="None">
            <Columns>
                <asp:BoundField DataField="zone_name" HeaderText="Zone" />
                <asp:BoundField DataField="business_type" HeaderText="Business type" />
                <asp:BoundField DataField="number_of_suborders" HeaderText="Order parts" />
                <asp:BoundField DataField="gross_sales" HeaderText="Sales (EGP)" DataFormatString="{0:N2}" />
                <asp:BoundField DataField="delivery_fees" HeaderText="Delivery fees (EGP)" DataFormatString="{0:N2}" />
                <asp:BoundField DataField="platform_commission" HeaderText="Platform commission (EGP)" DataFormatString="{0:N2}" />
            </Columns>
        </asp:GridView>
    </div>

    <%-- 3.3 e: who are the best riders of a period, and who is falling behind? --%>
    <div class="card" id="riders">
        <h2>Riders</h2>
        <p class="muted">Who are the best riders of a period, and who is falling behind?</p>
        <div class="row">
            <div class="field">
                <label>From</label>
                <asp:TextBox ID="ridersFrom" runat="server" TextMode="Date"></asp:TextBox>
            </div>
            <div class="field">
                <label>To</label>
                <asp:TextBox ID="ridersTo" runat="server" TextMode="Date"></asp:TextBox>
            </div>
            <div class="field field-button">
                <asp:Button ID="ridersBtn" runat="server" Text="Show riders" CssClass="btn" OnClick="ridersBtn_Click" />
            </div>
        </div>

        <h3>Top 5 riders of the period</h3>
        <asp:GridView ID="topRidersGrid" runat="server" AutoGenerateColumns="false" CssClass="grid" GridLines="None"
            EmptyDataText="No rider finished a delivery in this period.">
            <Columns>
                <asp:BoundField DataField="rider_rank" HeaderText="Rank" />
                <asp:BoundField DataField="rider_name" HeaderText="Rider" />
                <asp:BoundField DataField="completed_delivery_count" HeaderText="Deliveries completed" />
            </Columns>
        </asp:GridView>

        <h3>All riders (all time)</h3>
        <asp:Label ID="ridersSummary" runat="server" CssClass="msg"></asp:Label>
        <asp:GridView ID="allRidersGrid" runat="server" AutoGenerateColumns="false" CssClass="grid" GridLines="None"
            OnRowDataBound="allRidersGrid_RowDataBound">
            <Columns>
                <asp:BoundField DataField="rider_name" HeaderText="Rider" />
                <asp:BoundField DataField="zone_name" HeaderText="Zone" />
                <asp:BoundField DataField="completed_deliveries" HeaderText="Deliveries completed" />
                <asp:BoundField DataField="avg_rating" HeaderText="Avg rating" DataFormatString="{0:0.0} &#9733;" NullDisplayText="No ratings yet" HtmlEncode="false" />
                <asp:BoundField DataField="verdict" HeaderText="" />
            </Columns>
        </asp:GridView>
    </div>

    <%-- 3.3 f: what sells most, and which businesses do customers love or avoid? --%>
    <div class="card" id="market">
        <h2>Market</h2>
        <p class="muted">What sells most on the platform, and which businesses do customers love or avoid?</p>

        <h3>Top 10 selling products</h3>
        <asp:GridView ID="topProductsGrid" runat="server" AutoGenerateColumns="false" CssClass="grid" GridLines="None"
            EmptyDataText="Nothing was sold yet.">
            <Columns>
                <asp:BoundField DataField="product_name" HeaderText="Product" />
                <asp:BoundField DataField="business_name" HeaderText="Business" />
                <asp:BoundField DataField="business_type" HeaderText="Type" />
                <asp:BoundField DataField="units_sold" HeaderText="Units sold" />
                <asp:BoundField DataField="total_revenue" HeaderText="Revenue (EGP)" DataFormatString="{0:N2}" />
            </Columns>
        </asp:GridView>

        <div class="two-cols">
            <div>
                <h3>Loved: rated 4 stars or more</h3>
                <asp:GridView ID="lovedGrid" runat="server" AutoGenerateColumns="false" CssClass="grid" GridLines="None"
                    EmptyDataText="No business is rated 4 stars or more yet.">
                    <Columns>
                        <asp:BoundField DataField="business_name" HeaderText="Business" />
                        <asp:BoundField DataField="avg_rating" HeaderText="Avg rating" DataFormatString="{0:0.0} &#9733;" HtmlEncode="false" />
                        <asp:BoundField DataField="ratings_count" HeaderText="Ratings" />
                    </Columns>
                </asp:GridView>
            </div>
            <div>
                <h3>Avoided: rated below 3 stars</h3>
                <asp:GridView ID="avoidedGrid" runat="server" AutoGenerateColumns="false" CssClass="grid" GridLines="None"
                    EmptyDataText="No business is rated below 3 stars.">
                    <Columns>
                        <asp:BoundField DataField="business_name" HeaderText="Business" />
                        <asp:BoundField DataField="avg_rating" HeaderText="Avg rating" DataFormatString="{0:0.0} &#9733;" HtmlEncode="false" />
                        <asp:BoundField DataField="ratings_count" HeaderText="Ratings" />
                    </Columns>
                </asp:GridView>
            </div>
        </div>
        <asp:Label ID="unratedNote" runat="server" CssClass="muted"></asp:Label>
    </div>

</asp:Content>
