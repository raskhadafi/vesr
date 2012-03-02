class EsrFilesController < AuthorizedController
  before_filter :only => [:index, :show] do
    EsrRecord.update_unsolved_states
  end
end
