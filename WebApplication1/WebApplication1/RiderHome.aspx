<%@ Page Title="My deliveries" Language="C#" MasterPageFile="~/Rider.master" AutoEventWireup="true" CodeBehind="RiderHome.aspx.cs" Inherits="WebApplication1.RiderHome" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

    <asp:Label ID="msg" runat="server" CssClass="msg"></asp:Label>

    <%-- 3.4 e: my profile and my availability --%>
    <div class="card">
        <div class="card-head">
            <div>
                <h1><asp:Label ID="riderName" runat="server"></asp:Label></h1>
                <asp:Label ID="riderInfo" runat="server" CssClass="muted"></asp:Label>
            </div>
            <div class="availability">
                <asp:Label ID="availabilityBadge" runat="server" CssClass="status"></asp:Label>
                <asp:Button ID="toggleBtn" runat="server" CssClass="btn" OnClick="toggle_Click" />
            </div>
        </div>
    </div>

    <%-- 3.4 f: what do I do next? --%>
    <div class="card">
        <h2>What do I do next?</h2>
        <asp:Label ID="nextStep" runat="server" CssClass="msg"></asp:Label>

        <asp:Repeater ID="deliveries" runat="server" OnItemDataBound="deliveries_ItemDataBound" OnItemCommand="deliveries_ItemCommand">
            <ItemTemplate>
                <div class="delivery">
                    <div class="delivery-head">
                        <b>Order #<%# Eval("order_id") %></b> &middot; <%# HttpUtility.HtmlEncode((string)Eval("business_name")) %>
                        <span class="muted">assigned <%# ((DateTime)Eval("assigned_at")).ToString("d MMM, HH:mm") %></span>
                    </div>
                    <div class="delivery-body">
                        <div>
                            Deliver to <b><%# HttpUtility.HtmlEncode((string)Eval("customer_name")) %></b><br />
                            <%# HttpUtility.HtmlEncode((string)Eval("address_description")) %>, <%# HttpUtility.HtmlEncode((string)Eval("zone_name")) %>
                        </div>
                        <asp:Literal ID="steps" runat="server"></asp:Literal>
                        <asp:Button ID="actionBtn" runat="server" CssClass="btn" CommandArgument='<%# Eval("delivery_id") %>' />
                    </div>
                </div>
            </ItemTemplate>
        </asp:Repeater>
    </div>

</asp:Content>
