<%@ Page Title="Zones" Language="C#" MasterPageFile="~/Admin.master" AutoEventWireup="true" CodeBehind="AdminZones.aspx.cs" Inherits="WebApplication1.AdminZones" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

    <h1>Zones</h1>
    <p class="subtitle">Every zone of the platform and the delivery fee a customer pays for each business in it.</p>

    <asp:Label ID="msg" runat="server" CssClass="msg"></asp:Label>

    <%-- 3.3 b: all zones with their delivery fees --%>
    <div class="card">
        <h2>All zones</h2>
        <asp:GridView ID="zonesGrid" runat="server" AutoGenerateColumns="false" CssClass="grid" GridLines="None"
            EmptyDataText="There are no zones yet.">
            <Columns>
                <asp:BoundField DataField="zone_name" HeaderText="Zone" />
                <asp:BoundField DataField="delivery_fee" HeaderText="Delivery fee (EGP)" DataFormatString="{0:N2}" />
            </Columns>
        </asp:GridView>
        <asp:Label ID="zoneAdminNote" runat="server" CssClass="muted"></asp:Label>
    </div>

    <%-- 3.3 b: create a zone and change a zone's fee (Super Admin only) --%>
    <asp:Panel ID="superAdminPanel" runat="server">
        <div class="card">
            <h2>Create a zone</h2>
            <div class="row">
                <div class="field">
                    <label>Zone name</label>
                    <asp:TextBox ID="newZoneName" runat="server" MaxLength="50"></asp:TextBox>
                </div>
                <div class="field">
                    <label>Delivery fee (EGP)</label>
                    <asp:TextBox ID="newZoneFee" runat="server" TextMode="Number" step="0.01" min="0"></asp:TextBox>
                </div>
            </div>
            <asp:Button ID="createZoneBtn" runat="server" Text="Create zone" CssClass="btn" OnClick="createZone_Click" />
        </div>

        <div class="card">
            <h2>Change a zone's delivery fee</h2>
            <div class="row">
                <div class="field">
                    <label>Zone</label>
                    <asp:DropDownList ID="feeZone" runat="server"></asp:DropDownList>
                </div>
                <div class="field">
                    <label>New delivery fee (EGP)</label>
                    <asp:TextBox ID="newFee" runat="server" TextMode="Number" step="0.01" min="0"></asp:TextBox>
                </div>
            </div>
            <asp:Button ID="updateFeeBtn" runat="server" Text="Save new fee" CssClass="btn" OnClick="updateFee_Click" />
        </div>
    </asp:Panel>

</asp:Content>
