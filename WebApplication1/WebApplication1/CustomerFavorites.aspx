<%@ Page Title="Favorites" Language="C#" MasterPageFile="~/Customer.master" AutoEventWireup="true" CodeBehind="CustomerFavorites.aspx.cs" Inherits="WebApplication1.CustomerFavorites" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

    <h1>Favorites</h1>
    <p class="subtitle">Products and businesses you love, and products we think you will like.
        Add favorites from any <a href="CustomerBrowse.aspx">business page</a>.</p>

    <asp:Label ID="msg" runat="server" CssClass="msg"></asp:Label>

    <%-- 3.6 b: My_Favorites --%>
    <div class="card">
        <h2>My favorite products</h2>
        <asp:GridView ID="favProductsGrid" runat="server" AutoGenerateColumns="false" CssClass="grid" GridLines="None"
            DataKeyNames="product_id,product_name" OnRowCommand="grid_RowCommand" OnRowDataBound="favProductsGrid_RowDataBound"
            EmptyDataText="You have no favorite products yet.">
            <Columns>
                <asp:BoundField DataField="product_name" HeaderText="Product" />
                <asp:BoundField DataField="business_name" HeaderText="Business" />
                <asp:TemplateField HeaderText="Can I order it?">
                    <ItemTemplate><asp:Label ID="orderable" runat="server"></asp:Label></ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="">
                    <ItemTemplate>
                        <asp:Button ID="removeBtn" runat="server" Text="Remove" CssClass="btn btn-sm btn-secondary"
                            CommandName="RemoveProduct" CommandArgument="<%# Container.DataItemIndex %>" />
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
    </div>

    <%-- 3.6 b: favorite businesses (h_MyFavoriteBusinesses, Team_115.sql) --%>
    <div class="card">
        <h2>My favorite businesses</h2>
        <asp:GridView ID="favBusinessesGrid" runat="server" AutoGenerateColumns="false" CssClass="grid" GridLines="None"
            DataKeyNames="business_id,business_name" OnRowCommand="grid_RowCommand"
            EmptyDataText="You have no favorite businesses yet.">
            <Columns>
                <asp:HyperLinkField DataTextField="business_name" DataNavigateUrlFields="business_id"
                    DataNavigateUrlFormatString="~/BusinessPage.aspx?id={0}" HeaderText="Business" />
                <asp:BoundField DataField="zone_name" HeaderText="Zone" />
                <asp:BoundField DataField="status" HeaderText="Status" />
                <asp:TemplateField HeaderText="">
                    <ItemTemplate>
                        <asp:Button ID="removeBtn" runat="server" Text="Remove" CssClass="btn btn-sm btn-secondary"
                            CommandName="RemoveBusiness" CommandArgument="<%# Container.DataItemIndex %>" />
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
    </div>

    <%-- 3.6 b: Recommended_Products --%>
    <div class="card">
        <h2>Recommended for me</h2>
        <p class="muted">Products from the categories you order most, in your zone, that you have not tried yet.</p>
        <asp:GridView ID="recommendedGrid" runat="server" AutoGenerateColumns="false" CssClass="grid" GridLines="None"
            DataKeyNames="product_id,product_name" OnRowCommand="grid_RowCommand"
            EmptyDataText="No recommendations yet. Order a few times and we will suggest products you may like.">
            <Columns>
                <asp:BoundField DataField="product_name" HeaderText="Product" />
                <asp:BoundField DataField="business_name" HeaderText="Business" />
                <asp:BoundField DataField="category" HeaderText="Category" />
                <asp:BoundField DataField="final_price" HeaderText="Price (EGP)" DataFormatString="{0:N2}" />
                <asp:TemplateField HeaderText="">
                    <ItemTemplate>
                        <asp:Button ID="favBtn" runat="server" Text="♡ Add to favorites" CssClass="btn btn-sm btn-secondary"
                            CommandName="AddProduct" CommandArgument="<%# Container.DataItemIndex %>" />
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
    </div>

</asp:Content>
