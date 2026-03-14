class InvitesController < ApplicationController
  before_action :set_account
  skip_before_action :require_authentication, only: [ :accept, :register ]
  layout :choose_layout

  # GET /invites — team page with members + pending invites + invite form
  def index
    @managers = @account.managers.order(:created_at)
    @pending_invites = @account.invites.pending.order(created_at: :desc)
    @invite = Invite.new
  end

  # POST /invites — send an invite
  def create
    @invite = @account.invites.build(invite_params)
    @invite.invited_by = Current.manager

    if @invite.save
      InviteMailer.invite(@invite).deliver_later
      redirect_to invites_path, notice: "Invite sent to #{@invite.email}."
    else
      @managers = @account.managers.order(:created_at)
      @pending_invites = @account.invites.pending.order(created_at: :desc)
      render :index, status: :unprocessable_entity
    end
  end

  # DELETE /invites/:id — revoke a pending invite
  def destroy
    invite = @account.invites.pending.find(params[:id])
    invite.destroy
    redirect_to invites_path, notice: "Invite revoked."
  end

  # GET /invites/:token/accept — accept form (public, no auth)
  def accept
    @invite = Invite.find_by(token: params[:token])

    if @invite.nil? || @invite.accepted? || @invite.expired?
      redirect_to new_session_path, alert: "This invite link is invalid or has expired."
      return
    end

    @manager = Manager.new(email_address: @invite.email)
  end

  # POST /invites/:token/accept — create manager from invite (public, no auth)
  def register
    @invite = Invite.find_by(token: params[:token])

    if @invite.nil? || @invite.accepted? || @invite.expired?
      redirect_to new_session_path, alert: "This invite link is invalid or has expired."
      return
    end

    @manager = @invite.account.managers.build(manager_params)
    @manager.email_address = @invite.email

    if @manager.save
      @invite.update!(accepted_at: Time.current)
      start_session(@manager)
      redirect_to root_path, notice: "Welcome to #{@invite.account.name}!"
    else
      render :accept, status: :unprocessable_entity
    end
  end

  private

  def set_account
    @account = Current.account || Account.new
  end

  def choose_layout
    %w[accept register].include?(action_name) ? "auth" : "application"
  end

  def invite_params
    params.require(:invite).permit(:email)
  end

  def manager_params
    params.require(:manager).permit(:password, :password_confirmation)
  end
end
