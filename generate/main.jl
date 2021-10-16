using Pkg: Pkg
Pkg.activate(@__DIR__)
using Cascadia
using Gumbo
using CSV
using Markdown
using Downloads: download

include("piracy.jl")

function main()
    @info "starting"
    open(joinpath(dirname(@__DIR__), "README.md"), "w") do fh
        println(
            fh,
            """
            # 🐂 Hi Hi, I am Lyndon
            Feel encouraged to reach out to me. I like people.
            I am very contactable online. I am sure you can find me.

            GitHub doesn't make it easy to showcase all the projects I am involved in.
            Especially with so many being inside various github orgs.
            So I am using this profile README.md to experiment with providing something better.

            ***Note 1:** these lists are incomplete. When I find time I will remember the other 50 projects I am involved in.*\\
            ***Note 2:** this is just a list of projects I am involved in. A project listed here just means I think my involvement is in some sense significant. It doesn't mean I am running the project or even have commit rights.*
            """
        )
        write_section(fh, "main")
        println(fh)

        println(
            fh,
            """
            ## Dead-ends
            These are projects that I have spent a fair bit of time working on, but that I have now concluded are dead-ends.
            That they are not the way to continue to advance to solve this problem.
            They probably still function and work usefully.
            But they are deprecated and have other alternatives recommended.
            Not every project that I have abandonned is here, just ones that went a long way.
            You should ask me about why I think these are dead-ends, they are interesting things or they wouldn't have gotten this far.
            """
        )
        write_section(fh, "deadends")
        println(fh)

        println(
            fh,
            """

            ## Experiments and Early Ideas
            These are projects that are in an early stage, and exist more to prove a point.
            They may or may not be usable.
            I may or may not be actively working on them at this point in time.
            I might not have touched them in years.
            Regardless of this they are very cool ideas (in my very biased opinion).
            You should ask me about them.
            """
        )
        write_section(fh, "experiments")

        println(
            fh, 
            """

            ## Conclusion
            I hope this has been useful to you to see what I have been up to.
            Do reach out to me, as I said, I love talking to other humans.

            You can find the script that generates this profile [here](https://github.com/oxinabox/oxinabox).
            It's pretty fun little webscrapy markdown generaty thing.
            """
        )
    end

    @info "done"
end

function write_section(fh, section_name)
    @info "gathering data: $section_name"
    repo_urls = CSV.File(joinpath(dirname(@__DIR__), "data", "$section_name.csv")).repo
    infos = asyncmap(get_info, repo_urls)
    @info "writing content: $section_name"
    for project_info in infos
        show(fh, MIME("text/markdown"), project_info)
    end
    @info "done: $section_name"
end

Base.@kwdef struct ProjectInfo
    url
    user
    name
    description
    icon
end

read_url(url) = parsehtml(String(take!(download(url, IOBuffer()))))

function get_info(url)
    doc = read_url(url)
    get_only(sel) = only(eachmatch(sel, doc.root))
    user = text(only(eachmatch(sel"[itemprop='author']", doc.root)))

    
    description = get_only(sel"meta[name='description']")."content"
    # strip github's cruft
    description = replace(description, r" - GitHub - .*"=>"")
    description = replace(description, r" Contribute to .*"=>"")
    description = strip(description)

    return ProjectInfo(;
        url,
        user,
        name = text(only(eachmatch(sel"[itemprop='name']", doc.root))),
        description,
        icon = get_avatar_url(user),
    )
end

const _AVATAR_URL_CACHE = Dict{String,String}()
function get_avatar_url(user)
    get!(_AVATAR_URL_CACHE, user) do
        doc = read_url(joinpath("https://github.com", user))
        eles = eachmatch(sel"img[itemprop='image']", doc.root)
        if isempty(eles)  # probably means is personal repo not org repo
            eles = eachmatch(sel"img.avatar-user", doc.root)
        end
        return first(eles)."src"
    end
end


function Base.show(io::IO, ::MIME"text/markdown", info::ProjectInfo)
    print(io, " - ")
    print(io, "<a href='https://github.com/$(info.user)' title='$(info.user)'> <img src='$(info.icon)' height='20' width='20'/></a> ")
    print(io, "[**$(info.user)/$(info.name)**]($(info.url)): ")
    print(io, "_$(info.description)_")
    println(io)
end




main()
