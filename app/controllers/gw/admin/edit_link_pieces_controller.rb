class Gw::Admin::EditLinkPiecesController < Gw::Controller::Admin::Base
  include System::Controller::Scaffold
  layout "admin/template/admin"

  def pre_dispatch
    @is_gw_admin = Gw.is_admin_admin?
    @role_developer = Gw::EditLinkPiece.is_dev?
    @edit_link_piece_admin = Gw::EditLinkPiece.is_admin?
    @edit_link_piece_editor = Gw::EditLinkPiece.is_editor?
    @u_role = @is_gw_admin || @role_developer || @edit_link_piece_admin || @edit_link_piece_editor
    return error_auth unless @u_role

    @parent = params[:pid].present? ? Gw::EditLinkPiece.find_by(id: params[:pid]) : Gw::EditLinkPiece.root
    return http_error(404) unless @parent

    Page.title = "ポータルリンクピース編集"
  end

  def url_options
    super.merge(params.slice(:pid).symbolize_keys)
  end

  def index
    @items = Gw::EditLinkPiece.where(parent_id: @parent.id, uid: nil).order(sort_no: :asc)
      .paginate(page: params[:page], per_page: params[:limit])

    _index @items
  end

  def show
    @item = Gw::EditLinkPiece.find(params[:id])
  end

  def new
    @item = Gw::EditLinkPiece.new(
      parent_id: @parent.id,
      level_no: @parent.level_no + 1,
      mode: 1,
      state: 'enabled',
      published: 'opened',
      tab_keys: 0,
      sort_no: Gw::EditLinkPiece.where(parent_id: @parent.id).maximum(:sort_no).to_i + 10,
      class_created: 1,
      class_external: 1,
      class_sso: '1'
    )
  end

  def create
    @item = Gw::EditLinkPiece.new(params[:item])
    _create @item
  end

  def edit
    @item = Gw::EditLinkPiece.find(params[:id])
  end

  def update
    @item = Gw::EditLinkPiece.find(params[:id])
    @item.attributes = params[:item]
    _update @item
  end

  def destroy
    @item = Gw::EditLinkPiece.find(params[:id])
    @item.published      = 'closed'
    @item.state          = 'deleted'
    @item.tab_keys       = nil
    @item.sort_no        = nil
    @item.deleted_at     = Time.now
    @item.deleted_user   = Core.user.name
    @item.deleted_group  = Core.user_group.name
    @item.save(:validate => false)

    redirect_to url_for(action: :index), notice: '削除処理が完了しました。'
  end

  def sort_update
    @items = Gw::EditLinkPiece.where(parent_id: @parent.id, uid: nil).order(sort_no: :asc)
    params[:items].each do |id, param|
      item = @items.detect{|i| i.id == id.to_i}
      item.attributes = param if item
    end

    if @items.map(&:valid?).all?
      @items.each(&:save)
      redirect_to url_for(action: :index, pid: @parent.id), notice: '並び順を更新しました。'
    else
      flash.now[:notice] = '並び順の更新に失敗しました。'
      render :index
    end
  end

  def updown
    item = Gw::EditLinkPiece.find(params[:id])

    item_rep = case params[:order]
      when 'up'
        Gw::EditLinkPiece.where(parent_id: @parent.id).where("sort_no < #{item.sort_no}").order(sort_no: :desc).first
      when 'down'
        Gw::EditLinkPiece.where(parent_id: @parent.id).where("sort_no > #{item.sort_no}").order(sort_no: :asc).first
      end
    return http_error(404) unless item_rep

    item.sort_no, item_rep.sort_no = item_rep.sort_no, item.sort_no
    item.save(validate: false)
    item_rep.save(validate: false)
    redirect_to url_for(action: :index)
  end

  def swap
    item1 = Gw::EditLinkPiece.find(params[:id])
    item2 = Gw::EditLinkPiece.find(params[:sid])

    item1.sort_no, item2.sort_no = item2.sort_no, item1.sort_no
    item1.save(validate: false)
    item2.save(validate: false)
    redirect_to url_for(action: :index)
  end

  def list
    @items = Gw::EditLinkPiece.where(level_no: 2, uid: nil).order(state: :desc, sort_no: :asc)
  end
end
