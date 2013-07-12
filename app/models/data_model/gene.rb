module DataModel
  class Gene < ::ActiveRecord::Base
    include Genome::Extensions::UUIDPrimaryKey
    include Genome::Extensions::HasCacheableQuery
    has_and_belongs_to_many :gene_claims
    has_many :inter_gene_interaction_claims

    cache_query :all_gene_names, :all_gene_names

    def self.for_search
      eager_load(gene_claims: {interaction_claims: { source: [], drug_claim: [:source], interaction_claim_types: [], gene_claim: [genes: [gene_claims: [:gene_claim_categories]]]}})
    end

    def self.for_gene_categories
      eager_load(gene_claims: [:source, :gene_claim_categories])
    end

    def self.all_gene_names
      pluck(:name).sort
    end

    def self.for_show
      eager_load(gene_claims: [:gene_claim_aliases, :gene_claim_attributes, :genes, source: [:source_type]])
    end

  end
end
