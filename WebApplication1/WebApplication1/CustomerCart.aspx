<%@ Page Title="My cart" Language="C#" MasterPageFile="~/Customer.master" AutoEventWireup="true" CodeBehind="CustomerCart.aspx.cs" Inherits="WebApplication1.CustomerCart" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

    <h1>My cart</h1>
    <p class="subtitle"><asp:Label ID="addressLine" runat="server"></asp:Label></p>

    <asp:Label ID="msg" runat="server" CssClass="msg"></asp:Label>

    <%-- 3.5 d: create a cart for my active address --%>
    <asp:Panel ID="noCartPanel" runat="server" CssClass="card" Visible="false">
        <h2>You have no cart for your active address</h2>
        <p class="muted">A cart belongs to one address. Start one, then add products from the businesses of your zone.</p>
        <div class="btn-row">
            <asp:Button ID="createBtn" runat="server" Text="Start a cart" CssClass="btn" OnClick="create_Click" />
            <a class="btn btn-secondary" href="CustomerBrowse.aspx">Browse businesses</a>
        </div>
    </asp:Panel>

    <%-- 3.5 d: the products in my cart; remove products --%>
    <asp:Panel ID="cartPanel" runat="server" CssClass="card" Visible="false">
        <div class="card-head">
            <h2>Products in my cart</h2>
            <a href="CustomerBrowse.aspx">+ Add more products</a>
        </div>
        <asp:GridView ID="itemsGrid" runat="server" AutoGenerateColumns="false" CssClass="grid" GridLines="None"
            DataKeyNames="product_id,product_name" OnRowCommand="itemsGrid_RowCommand" OnRowDataBound="itemsGrid_RowDataBound"
            EmptyDataText="Your cart is empty. Add products from a business page.">
            <Columns>
                <asp:BoundField DataField="product_name" HeaderText="Product" />
                <asp:BoundField DataField="business_name" HeaderText="Business" />
                <asp:BoundField DataField="quantity" HeaderText="Qty" />
                <asp:BoundField DataField="notes" HeaderText="Note" NullDisplayText="-" />
                <asp:BoundField DataField="unit_price" HeaderText="Unit price" DataFormatString="{0:N2}" />
                <asp:BoundField DataField="line_total" HeaderText="Total (EGP)" DataFormatString="{0:N2}" />
                <asp:TemplateField HeaderText="">
                    <ItemTemplate>
                        <asp:Label ID="unavailable" runat="server" CssClass="status status-Suspended" Text="Not available" Visible="false"></asp:Label>
                        <asp:Button ID="removeBtn" runat="server" Text="Remove" CssClass="btn btn-sm btn-secondary"
                            CommandName="RemoveItem" CommandArgument="<%# Container.DataItemIndex %>" />
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
        <div class="cart-footer">
            <span>Products: <b><asp:Label ID="subtotal" runat="server"></asp:Label> EGP</b>
                <span class="muted">(delivery fees and vouchers are added at checkout)</span></span>
            <asp:HyperLink ID="checkoutLink" runat="server" NavigateUrl="~/CustomerCheckout.aspx" CssClass="btn">Go to checkout</asp:HyperLink>
        </div>
    </asp:Panel>

</asp:Content>
