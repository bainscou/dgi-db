class InteractionSearchResultPresenter
  include Genome::Extensions

  attr_accessor :search_term, :interaction_claim
  def initialize(interaction_claim, search_term, view_context)
    @interaction_claim = interaction_claim
    @search_term = search_term
    @view_context = view_context
  end

  def source_db_name
    @interaction_claim.source.source_db_name
  end

  def source_db_version
    @interaction_claim.source.source_db_version
  end

  def source_db_url
    @interaction_claim.source.site_url
  end

  def drug_claim_name
    @interaction_claim.drug_claim.primary_name || @interaction_claim.drug_claim.name
  end

  def trust_level
    @interaction_claim.source.source_trust_level.level
  end

  def source_link
    TrustLevelPresenter.source_link_with_trust_flag(@view_context, @interaction_claim.source)
  end

  def types_string
    @types_string ||= @interaction_claim
      .interaction_claim_types
      .map{ |x| x.type.sub(/^na$/,'n/a') }
      .join('/')
  end

  def gene_name
    @interaction_claim.gene_claim.genes.first.name
  end

  def gene_long_name
    @interaction_claim.gene_claim.genes.first.long_name
  end

  def potentially_druggable_categories
    @interaction_claim.gene_claim
      .genes.first
      .gene_claims
      .flat_map { |gc| gc.gene_claim_categories }
      .map { |c| c.name }
      .uniq
  end
end

