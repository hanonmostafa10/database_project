<%@ Page Title="Checkout" Language="C#" MasterPageFile="~/Customer.master" AutoEventWireup="true" CodeBehind="CustomerCheckout.aspx.cs" Inherits="WebApplication1.CustomerCheckout" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

    <p><a href="CustomerCart.aspx">&larr; Back to my cart</a></p>
    <h1>Checkout</h1>
    <p class="subtitle"><asp:Label ID="addressLine" runat="server"></asp:Label></p>

    <asp:Label ID="msg" runat="server" CssClass="msg"></asp:Label>

    <asp:Panel ID="checkoutPanel" runat="server">
        <div class="checkout">
            <%-- 3.5 e: what exactly will I pay, and why? --%>
            <div class="card">
                <h2>What you will pay</h2>
                <asp:Literal ID="breakdown" runat="server"></asp:Literal>
                <asp:BulletedList ID="problemsList" runat="server" CssClass="issues problems"></asp:BulletedList>
            </div>

            <%-- 3.5 e: payment method and optional voucher --%>
            <div class="card">
                <h2>How you will pay</h2>
                <div class="field">
                    <label>Voucher <span class="hint">(optional)</span></label>
                    <asp:DropDownList ID="voucher" runat="server" AutoPostBack="true" OnSelectedIndexChanged="options_Changed"></asp:DropDownList>
                </div>
                <div class="field">
                    <label>Payment method</label>
                    <asp:RadioButtonList ID="method" runat="server" AutoPostBack="true" OnSelectedIndexChanged="options_Changed" CssClass="radio">
                        <asp:ListItem Value="Cash" Selected="True">Cash on delivery</asp:ListItem>
                        <asp:ListItem Value="Card">Card</asp:ListItem>
                        <asp:ListItem Value="Wallet">Wallet</asp:ListItem>
                    </asp:RadioButtonList>
                    <asp:Label ID="walletLine" runat="server" CssClass="muted"></asp:Label>
                </div>
                <asp:Panel ID="cardPanel" runat="server" CssClass="field" Visible="false">
                    <label>Card</label>
                    <asp:DropDownList ID="card" runat="server"></asp:DropDownList>
                    <asp:Label ID="cardHint" runat="server" CssClass="muted"></asp:Label>
                </asp:Panel>
                <asp:Button ID="placeBtn" runat="server" CssClass="btn btn-full" OnClick="place_Click" />
            </div>
        </div>
    </asp:Panel>

    <asp:Panel ID="donePanel" runat="server" CssClass="card" Visible="false">
        <h2>Thank you!</h2>
        <p>Your order is on its way. You can follow every part of it on the orders page.</p>
        <a class="btn" href="CustomerOrders.aspx">Track my order</a>
    </asp:Panel>

</asp:Content>
