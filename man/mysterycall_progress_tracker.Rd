% Generated manually; keep in sync with R/progress_tracker.R
\name{mysterycall_progress_tracker}
\alias{mysterycall_progress_tracker}
\title{Track multi-stage workflow progress}
\description{
Creates a progress tracker object for recording per-step status, emitting
periodic progress updates, and surfacing quality tiers for long-running
workflows.
}
\usage{
mysterycall_progress_tracker(steps, update_every = 300,
  quiet = getOption("mysterycall.quiet", FALSE))
}
\arguments{
\item{steps}{Character vector naming each workflow stage.}

\item{update_every}{Number of seconds between automatic update messages.}

\item{quiet}{Logical flag that suppresses log output when \code{TRUE}.}
}
\value{
An object of class \code{mysterycall_progress_tracker}.  Pass it to
\code{\link{mysterycall_progress_start}()},
\code{\link{mysterycall_progress_finish}()},
\code{\link{mysterycall_tracker_fail}()},
\code{\link{mysterycall_tracker_update}()}, and
\code{\link{mysterycall_progress_summary}()}.
}
\examples{
tracker <- mysterycall:::mysterycall_progress_tracker(c("Geocode", "Validate"), update_every = 10)
mysterycall:::mysterycall_progress_start(tracker, "Geocode")
mysterycall:::mysterycall_progress_finish(tracker, "Geocode", score = 0.92)
mysterycall:::mysterycall_progress_summary(tracker)
}
\keyword{internal}
