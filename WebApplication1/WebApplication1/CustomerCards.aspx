<%@ Page Title="My cards" Language="C#" MasterPageFile="~/Customer.master" AutoEventWireup="true" CodeBehind="CustomerCards.aspx.cs" Inherits="WebApplication1.CustomerCards" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

    <h1>My cards</h1>
    <p class="subtitle">Save a card to pay with it at checkout. Only the last 4 digits of a card are ever shown.</p>

    <asp:Label ID="msg" runat="server" CssClass="msg"></asp:Label>

    <div class="card">
        <h2>Saved cards</h2>
        <asp:GridView ID="cardsGrid" runat="server" AutoGenerateColumns="false" CssClass="grid" GridLines="None"
            OnRowDataBound="cardsGrid_RowDataBound" EmptyDataText="You have no saved cards yet.">
            <Columns>
                <asp:BoundField DataField="last_four_digits" HeaderText="Card" DataFormatString="&bull;&bull;&bull;&bull; {0}" HtmlEncode="false" />
                <asp:BoundField DataField="card_holder_name" HeaderText="Name on card" />
                <asp:BoundField DataField="expiration_date" HeaderText="Expires" DataFormatString="{0:MM/yyyy}" />
                <asp:TemplateField HeaderText="">
                    <ItemTemplate>
                        <asp:Label ID="expiredBadge" runat="server"></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
    </div>

    <%-- 3.5 c: save a card --%>
    <div class="card">
        <h2>Save a new card</h2>
        <div class="row">
            <div class="field">
                <label>Card number <span class="hint">(16 digits)</span></label>
                <asp:TextBox ID="cardNo" runat="server" MaxLength="19" autocomplete="off" placeholder="1234 5678 9012 3456"></asp:TextBox>
            </div>
            <div class="field">
                <label>Name on card</label>
                <asp:TextBox ID="holderName" runat="server" MaxLength="100"></asp:TextBox>
            </div>
            <div class="field">
                <label>Expires</label>
                <asp:TextBox ID="expiry" runat="server" TextMode="Month"></asp:TextBox>
            </div>
        </div>
        <asp:Button ID="saveBtn" runat="server" Text="Save card" CssClass="btn" OnClick="save_Click" />
    </div>

</asp:Content>
