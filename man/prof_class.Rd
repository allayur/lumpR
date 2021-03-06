% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/prof_class.R
\name{prof_class}
\alias{prof_class}
\title{Classification of mean catenas}
\usage{
prof_class(catena_file = NULL, catena_head_file = NULL,
  svc_column = "svc", dir_out = "./", luoutfile = "lu.dat",
  tcoutfile = "tc.dat", lucontainstcoutfile = "lucontainstc.dat",
  tccontainssvcoutfile = "r_tc_contains_svc.dat",
  terraincomponentsoutfile = "terraincomponents.dat",
  recl_lu = "reclass_lu.txt", saved_clusters = NULL, seed = 1312,
  resolution = NULL, classify_type = " ", max_com_length = NULL,
  com_length = NULL, make_plots = F, eha_subset = NULL,
  eha_blacklist = NULL, overwrite = F, silent = F,
  plot_silhouette = T)
}
\arguments{
\item{catena_file}{Name of file containing mean catena information derived from
\code{\link[lumpR]{area2catena}}.}

\item{catena_head_file}{Name of file containing meta-information for classification
derived from \code{\link[lumpR]{area2catena}} and adjusted manually (see \code{Notes}).}

\item{svc_column}{Field name in \code{catena_head_file} that holds the information
of SVCs for generating \code{tccontainssvcoutfile}. Default: 'svc'.}

\item{dir_out}{Character string specifying output directory (will be created;
nothing will be overwritten).}

\item{luoutfile}{Output: Name of file containing the average properties of
\emph{Landscape Units}.}

\item{tcoutfile}{Output: Name of file containing the average properties of
\emph{Terrain Components}.}

\item{lucontainstcoutfile}{Output: Name of file containing information wich
LU contains which TCs.}

\item{tccontainssvcoutfile}{Output: Name of file containing information wich
TC contains which SVCs.}

\item{terraincomponentsoutfile}{Output: Name of file containing general
properties of TCs.}

\item{recl_lu}{Output: Name of GRASS reclassification file: EHA -> LU.}

\item{saved_clusters}{Output: Name of R file that can be used to store LU
characteristics for later re-use; set to NULL to omit output (default).}

\item{seed}{Integer specifying seed for random processes in cluster analysis.}

\item{resolution}{Integer specifying resolution of profiles/spacing of samples.
Typically the resolution of your GRASS location used for \code{\link[lumpR]{area2catena}}.}

\item{classify_type}{Type of classification:\cr
' ': (default) unsupervised classification, no \code{saved_clusters} will be produced\cr
'save': do unsupervised classification and save cluster centers to \code{saved_clusters}
        for future supervised classification\cr
'load': load cluster centers from existing file and classify according
        to these clusters (e.g. supervised classification). CURRENTLY NOT SUPPORTED!}

\item{max_com_length}{Integer defining the maximum common length of profiles,
i.e. the maximum number of support points representing each catena during the
classification procedure. Too large values consume more memory and computational
effort.}

\item{com_length}{Integer giving common length of profiles, i.e. the number of
support points representing each catena during the classification procedure.
Too large values consume more memory and computational effort. Overwrites
max_com_length.}

\item{make_plots}{logical; visualisation of classification results written into
sub-directory \emph{plots_prof_class}. WARNING: Consumes a lot of processing
time and memory. Default: \code{FALSE}.}

\item{eha_subset}{NULL or integer vector with subset of EHA ids that shall
be processed (for debugging and testing).}

\item{eha_blacklist}{NULL or integer vector with subset of EHA ids that will
be excluded (use this for manual exclusion of strange profiles).}

\item{overwrite}{\code{logical}. Shall output of previous calls of this function be
deleted? If \code{FALSE} the function returns an error if output already exists.
Default: \code{FALSE}.}

\item{silent}{\code{logical}. Shall the function be silent (also suppressing warnings)?
Default: \code{FALSE}.}

\item{plot_silhouette}{\code{logical}. Shall a silhouette plot (illustrating the clustering
process) be generated? Consumes much memory and processing time and should be disabled,
if a memory error is thrown. Will be \code{FALSE} if \code{make_plots = FALSE}.
Default: \code{TRUE}.}
}
\value{
Function returns nothing. Output files are written into output directory
     as specified in arguments.
}
\description{
Classifies mean catenas derived from \code{\link[lumpR]{area2catena}} into \emph{Landscape
Units} and \emph{Terrain Components}.
}
\details{
This function first resamples the catenas derived from \code{\link[lumpR]{area2catena}}
     to a common length (\code{com_length} or the median number of support points
     of all catenas but not more than \code{max_com_length}). Second, k-means clustering
     is employed to group the catenas into representative \emph{Landscape Units}
     according to parameters given via \code{catena_head_file} taking into account
     hillslope length, shape, and supplemental properties. Third, each group is further
     partitioned into a given number of \emph{Terrain Components} in a way that the
     variance within each TC is minimized considering slope gradient and supplemental
     information.
}
\note{
Function uses output of \code{\link[lumpR]{area2catena}}. However, no GRASS
     session needs to be started in this case.
     
     After applying \code{recl_lu}, the resulting landscape units raster map in your GRASS
     location might show gaps depending on the number of generated landscape units
     as each landscape unit refers to the representative EHA. The gaps can be filled
     with GRASS function \code{r.grow}.
     
     In case of \bold{long computation times or memory issues}, try \code{make_plots = FALSE}
     and specify an RData file as \code{catena_file} (already in \code{\link[lumpR]{area2catena}}).
}
\references{
Source code based on \code{SHELL} and \code{MATLAB} scripts of Till Francke.

     lumpR package introduction with literature study and sensitivity analysis:\cr
     Pilz, T.; Francke, T.; Bronstert, A. (2017): lumpR 2.0.0: an R package facilitating
     landscape discretisation for hillslope-based hydrological models.
     \emph{Geosci. Model Dev.}, 10, 3001-3023, doi: 10.5194/gmd-10-3001-2017

     Theory of LUMP:\cr
     Francke, T.; Guentner, A.; Mamede, G.; Mueller, E. N. and Bronstert, A (2008):
     Automated catena-based discretization of landscapes for the derivation of
     hydrological modelling units. \emph{International Journal of Geographical
     Information Science, Informa UK Limited}, 22(2), 111-132, DOI: 10.1080/13658810701300873
}
\author{
Tobias Pilz \email{tpilz@uni-potsdam.de}, Till Francke \email{francke@uni-potsdam.de}
}
