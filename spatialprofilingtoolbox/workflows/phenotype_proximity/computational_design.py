"""
The module describing the design of the phenotype proximity workflow, including
any workflow-specific metadata.
"""
import pandas as pd

from ...environment.computational_design import ComputationalDesign


class PhenotypeProximityDesign(ComputationalDesign):
    """
    The design object.
    """
    def __init__(self,
        dataset_design=None,
        complex_phenotypes_file: str=None,
        balanced: bool=False,
        **kwargs,
    ):
        """
        :param dataset_design: The design object describing the input data set.

        :param complex_phenotypes_file: The table of composite phenotypes to be
            considered.
        :type complex_phenotypes_file: str

        :param balanced: Whether to use balanced or unbalanced treatment of phenotype
            pairs.
        :type balanced: bool
        """
        super().__init__(**kwargs)
        self.dataset_design = dataset_design
        self.complex_phenotypes = pd.read_csv(
            complex_phenotypes_file,
            keep_default_na=False,
        )
        self.balanced = balanced

    @staticmethod
    def get_database_uri():
        return 'phenotype_proximity.db'

    def get_stats_tests_file(self):
        """
        :return: The filename to use when writing the statistical test results.
        :rtype: str
        """
        if self.balanced:
            return 'phenotype_2_phenotype_balanced_proximity_tests.csv'
        else:
            return 'phenotype_2_phenotype_proximity_tests.csv'

    @staticmethod
    def get_cell_pair_counts_table_header():
        """
        :return: A list of 2-tuples, each of which is a column name followed by
            SQL-style datatype name, describing the schema for the cell pair counts
            intermediate data table.
        :rtype: list of 2-tuples
        """
        return [
            ('sample_identifier', 'TEXT'),
            ('outcome_assignment', 'TEXT'),
            ('source_phenotype', 'TEXT'),
            ('target_phenotype', 'TEXT'),
            ('compartment', 'TEXT'),
            ('distance_limit_in_pixels', 'INTEGER'),
            ('cell_pair_count_per_FOV', 'NUMERIC'),
        ]

    def get_all_phenotype_signatures(self, by_name=False):
        """
        :param by_name: Whether to return a list (default) or a dictionary whose keys
            are the munged names. (Default False).
        :type by_name: bool

        :return: ``signature``. Signatures for all the composite phenotypes described by
            the ``complex_phenotypes_file`` table. Each signature is a dictionary with
            keys the elementary phenotypes and values either "+" or "-".
        :rtype: list
        """
        elementary_signatures = [
            {name : '+'} for name in self.dataset_design.get_elementary_phenotype_names()
        ]
        complex_signatures = []
        for _, row in self.complex_phenotypes.iterrows():
            positive_markers = sorted([m for m in row['Positive markers'].split(';') if m != ''])
            negative_markers = sorted([m for m in row['Negative markers'].split(';') if m != ''])
            signature = {}
            for marker in positive_markers:
                signature[marker] = '+'
            for marker in negative_markers:
                signature[marker] = '-'
            complex_signatures.append(signature)
        signatures = elementary_signatures + complex_signatures
        if by_name:
            return {
                self.dataset_design.munge_name(signature) : signature for signature in signatures
            }
        return signatures

    def get_all_phenotype_names(self):
        """
        :return: All (composite) phenotype names.
        :rtype: list
        """
        return sorted(list(self.get_all_phenotype_signatures(by_name=True).keys()))

    @staticmethod
    def get_primary_output_feature_name():
        """
        :return: The name of the main numerical feature produced by the jobs.
        :rtype: str
        """
        return 'cell pair count per FOV'
