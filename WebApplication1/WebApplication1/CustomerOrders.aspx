<%@ Page Title="My orders" Language="C#" MasterPageFile="~/Customer.master" AutoEventWireup="true" CodeBehind="CustomerOrders.aspx.cs" Inherits="WebApplication1.CustomerOrders" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

    <h1>My orders</h1>
    <p class="subtitle">Where is my order now, and when will it arrive?</p>

    <asp:Label ID="msg" runat="server" CssClass="msg"></asp:Label>

    <%-- 3.6 e: feedback form for a delivered part --%>
    <asp:Panel ID="feedbackPanel" runat="server" CssClass="card" Visible="false">
        <h2><asp:Label ID="feedbackTitle" runat="server"></asp:Label></h2>
        <div class="row">
            <div class="field">
                <label>Headline</label>
                <asp:TextBox ID="fbHeadline" runat="server" MaxLength="100" placeholder="e.g. Hot and tasty"></asp:TextBox>
            </div>
            <div class="field">
                <label>Rating</label>
                <asp:DropDownList ID="fbRating" runat="server">
                    <asp:ListItem Value="">-- Choose --</asp:ListItem>
                    <asp:ListItem Value="5">5 - Excellent</asp:ListItem>
                    <asp:ListItem Value="4">4 - Good</asp:ListItem>
                    <asp:ListItem Value="3">3 - OK</asp:ListItem>
                    <asp:ListItem Value="2">2 - Poor</asp:ListItem>
                    <asp:ListItem Value="1">1 - Bad</asp:ListItem>
                </asp:DropDownList>
            </div>
        </div>
        <div class="field">
            <label>Details <span class="hint">(optional)</span></label>
            <asp:TextBox ID="fbDescription" runat="server" TextMode="MultiLine" Rows="2" MaxLength="500"></asp:TextBox>
        </div>
        <div class="btn-row">
            <asp:Button ID="fbSubmitBtn" runat="server" Text="Send feedback" CssClass="btn" OnClick="feedback_Click" />
            <asp:Button ID="fbCancelBtn" runat="server" Text="Cancel" CssClass="btn btn-secondary" OnClick="closePanels_Click" />
        </div>
    </asp:Panel>

    <%-- 3.6 d: reorder a past order to one of my addresses --%>
    <asp:Panel ID="reorderPanel" runat="server" CssClass="card" Visible="false">
        <h2><asp:Label ID="reorderTitle" runat="server"></asp:Label></h2>
        <p class="muted">The available products of this order are copied into a new cart for the address you choose,
            and that address becomes your active address. The address must be in the same zone as the order.</p>
        <div class="field">
            <label>Deliver to</label>
            <asp:DropDownList ID="reorderAddress" runat="server"></asp:DropDownList>
        </div>
        <div class="btn-row">
            <asp:Button ID="reorderBtn" runat="server" Text="Reorder" CssClass="btn" OnClick="reorder_Click" />
            <asp:Button ID="reorderCancelBtn" runat="server" Text="Cancel" CssClass="btn btn-secondary" OnClick="closePanels_Click" />
        </div>
    </asp:Panel>

    <asp:Label ID="noOrders" runat="server" CssClass="msg msg-warning" Visible="false">
        You have no orders yet. <a href="CustomerBrowse.aspx">Find something you like</a>.
    </asp:Label>

    <%-- 3.6 c: My_Order_History, and each part of an order with its progress (h_OrderSubOrders) --%>
    <asp:Repeater ID="ordersRepeater" runat="server" OnItemDataBound="ordersRepeater_ItemDataBound" OnItemCommand="ordersRepeater_ItemCommand">
        <ItemTemplate>
            <div class="card order">
                <div class="card-head">
                    <div>
                        <h2>Order #<%# Eval("order_id") %>
                            <span class='status status-<%# ((string)Eval("status")).Replace(" ", "") %>'><%# Eval("status") %></span></h2>
                        <span class="muted"><%# ((DateTime)Eval("order_date")).ToString("d MMM yyyy, HH:mm") %> &middot; <%# HttpUtility.HtmlEncode((string)Eval("zone_name")) %>
                            &middot; <%# Eval("number_of_suborders") %> part(s)</span>
                    </div>
                    <div class="order-total">
                        <b><%# ((decimal)Eval("total_amount")).ToString("N2") %> EGP</b><br />
                        <span class="muted"><asp:Label ID="paymentLine" runat="server"></asp:Label></span>
                    </div>
                </div>
                <asp:Label ID="etaLine" runat="server" CssClass="msg"></asp:Label>

                <asp:Repeater ID="partsRepeater" runat="server" OnItemDataBound="partsRepeater_ItemDataBound" OnItemCommand="partsRepeater_ItemCommand">
                    <ItemTemplate>
                        <div class="part">
                            <div class="part-main">
                                <b><%# HttpUtility.HtmlEncode((string)Eval("business_name")) %></b>
                                <span class="muted"><%# ((decimal)Eval("total_price")).ToString("N2") %> + <%# ((decimal)Eval("delivery_fee")).ToString("N2") %> delivery</span><br />
                                <asp:Label ID="riderLine" runat="server" CssClass="muted"></asp:Label>
                            </div>
                            <asp:Literal ID="steps" runat="server"></asp:Literal>
                            <asp:Label ID="partEta" runat="server" CssClass="part-eta"></asp:Label>
                            <div class="part-actions">
                                <asp:Button ID="feedbackBtn" runat="server" Text="Leave feedback" CssClass="btn btn-sm btn-secondary"
                                    CommandName="Feedback" CommandArgument='<%# Eval("suborder_id") %>' Visible="false" />
                                <asp:Label ID="feedbackDone" runat="server" CssClass="muted" Text="Feedback sent" Visible="false"></asp:Label>
                                <asp:Panel ID="ratePanel" runat="server" CssClass="rate" Visible="false">
                                    <asp:DropDownList ID="riderRating" runat="server">
                                        <asp:ListItem Value="">Rate rider</asp:ListItem>
                                        <asp:ListItem Value="5">5 &#9733;</asp:ListItem>
                                        <asp:ListItem Value="4">4 &#9733;</asp:ListItem>
                                        <asp:ListItem Value="3">3 &#9733;</asp:ListItem>
                                        <asp:ListItem Value="2">2 &#9733;</asp:ListItem>
                                        <asp:ListItem Value="1">1 &#9733;</asp:ListItem>
                                    </asp:DropDownList>
                                    <asp:Button ID="rateBtn" runat="server" Text="Rate" CssClass="btn btn-sm"
                                        CommandName="RateRider" CommandArgument='<%# Eval("suborder_id") %>' />
                                </asp:Panel>
                                <asp:Label ID="ratedLine" runat="server" CssClass="muted" Visible="false"></asp:Label>
                            </div>
                        </div>
                    </ItemTemplate>
                </asp:Repeater>

                <div class="btn-row order-actions">
                    <asp:Button ID="cancelBtn" runat="server" Text="Cancel order" CssClass="btn btn-sm btn-danger"
                        CommandName="CancelOrder" CommandArgument='<%# Eval("order_id") %>' Visible="false" />
                    <asp:Button ID="reorderOpenBtn" runat="server" Text="Reorder" CssClass="btn btn-sm btn-secondary"
                        CommandName="Reorder" CommandArgument='<%# Eval("order_id") %>' />
                </div>
            </div>
        </ItemTemplate>
    </asp:Repeater>

</asp:Content>
