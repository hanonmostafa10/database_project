<%@ Page Title="My business" Language="C#" MasterPageFile="~/Partner.master" AutoEventWireup="true" CodeBehind="PartnerHome.aspx.cs" Inherits="WebApplication1.PartnerHome" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

    <asp:Label ID="msg" runat="server" CssClass="msg"></asp:Label>

    <%-- 3.4 b: always see where my business stands --%>
    <asp:Panel ID="statusPanel" runat="server" CssClass="card">
        <h1><asp:Label ID="bizTitle" runat="server"></asp:Label>
            <asp:Label ID="statusBadge" runat="server" CssClass="status"></asp:Label></h1>
        <asp:Label ID="statusText" runat="server" CssClass="msg"></asp:Label>

        <asp:Panel ID="detailsPanel" runat="server">
            <table class="details">
                <tr><th>Type</th><td><asp:Label ID="dType" runat="server"></asp:Label></td></tr>
                <tr><th>Zone</th><td><asp:Label ID="dZone" runat="server"></asp:Label></td></tr>
                <tr><th>Opening hours</th><td><asp:Label ID="dHours" runat="server"></asp:Label></td></tr>
                <tr><th>Expected delivery time</th><td><asp:Label ID="dDelivery" runat="server"></asp:Label></td></tr>
                <tr><th>Website</th><td><asp:Label ID="dWebsite" runat="server"></asp:Label></td></tr>
                <tr><th>Description</th><td><asp:Label ID="dDescription" runat="server"></asp:Label></td></tr>
                <tr><th>Phones</th><td><asp:Label ID="dPhones" runat="server"></asp:Label></td></tr>
            </table>
        </asp:Panel>
    </asp:Panel>

    <%-- 3.4 b: update my hours and website and add a phone number --%>
    <asp:Panel ID="updatePanel" runat="server" CssClass="card">
        <h2>Update my business</h2>
        <div class="row">
            <div class="field">
                <label>Opens at</label>
                <asp:TextBox ID="updOpen" runat="server" TextMode="Time"></asp:TextBox>
            </div>
            <div class="field">
                <label>Closes at <span class="hint">(same as opening = open 24 hours)</span></label>
                <asp:TextBox ID="updClose" runat="server" TextMode="Time"></asp:TextBox>
            </div>
        </div>
        <div class="row">
            <div class="field">
                <label>Website <span class="hint">(leave empty to keep the current one)</span></label>
                <asp:TextBox ID="updWebsite" runat="server" MaxLength="255"></asp:TextBox>
            </div>
            <div class="field">
                <label>Add a phone number <span class="hint">(optional, 11 digits)</span></label>
                <asp:TextBox ID="updPhone" runat="server" MaxLength="11"></asp:TextBox>
            </div>
        </div>
        <asp:Button ID="updateBtn" runat="server" Text="Save changes" CssClass="btn" OnClick="update_Click" />
    </asp:Panel>

    <%-- 3.4 b: register my business (again, if it was Rejected) --%>
    <asp:Panel ID="registerPanel" runat="server" CssClass="card">
        <h2><asp:Label ID="registerTitle" runat="server"></asp:Label></h2>
        <p class="muted">An admin of your zone reviews every new business before customers can see it.</p>
        <div class="row">
            <div class="field">
                <label>Business name</label>
                <asp:TextBox ID="regName" runat="server" MaxLength="100"></asp:TextBox>
            </div>
            <div class="field">
                <label>Zone</label>
                <asp:DropDownList ID="regZone" runat="server"></asp:DropDownList>
            </div>
        </div>
        <div class="field">
            <label>Description <span class="hint">(optional)</span></label>
            <asp:TextBox ID="regDescription" runat="server" MaxLength="255"></asp:TextBox>
        </div>
        <div class="row">
            <div class="field">
                <label>Opens at</label>
                <asp:TextBox ID="regOpen" runat="server" TextMode="Time"></asp:TextBox>
            </div>
            <div class="field">
                <label>Closes at</label>
                <asp:TextBox ID="regClose" runat="server" TextMode="Time"></asp:TextBox>
            </div>
            <div class="field">
                <label>Expected delivery time (minutes)</label>
                <asp:TextBox ID="regDelivery" runat="server" TextMode="Number" min="1"></asp:TextBox>
            </div>
        </div>
        <div class="row">
            <div class="field">
                <label>Website <span class="hint">(optional)</span></label>
                <asp:TextBox ID="regWebsite" runat="server" MaxLength="255"></asp:TextBox>
            </div>
            <div class="field">
                <label>Phone <span class="hint">(optional, 11 digits)</span></label>
                <asp:TextBox ID="regPhone" runat="server" MaxLength="11"></asp:TextBox>
            </div>
        </div>
        <div class="field">
            <label>Business type</label>
            <asp:DropDownList ID="regType" runat="server" AutoPostBack="true" OnSelectedIndexChanged="regType_Changed">
                <asp:ListItem Value="Restaurant">Restaurant</asp:ListItem>
                <asp:ListItem Value="Pharmacy">Pharmacy</asp:ListItem>
            </asp:DropDownList>
        </div>
        <asp:Panel ID="restaurantPanel" runat="server" CssClass="row">
            <div class="field">
                <label>Cuisine</label>
                <asp:TextBox ID="regCuisine" runat="server" MaxLength="50" placeholder="e.g. Egyptian"></asp:TextBox>
            </div>
            <div class="field">
                <label>Food category</label>
                <asp:TextBox ID="regFoodCategory" runat="server" MaxLength="50" placeholder="e.g. Street food"></asp:TextBox>
            </div>
        </asp:Panel>
        <asp:Panel ID="pharmacyPanel" runat="server" CssClass="field" Visible="false">
            <label>Pharmacy type</label>
            <asp:TextBox ID="regPharmacyType" runat="server" MaxLength="50" placeholder="e.g. Community pharmacy"></asp:TextBox>
        </asp:Panel>
        <asp:Button ID="registerBtn" runat="server" Text="Send for approval" CssClass="btn" OnClick="register_Click" />
    </asp:Panel>

</asp:Content>
