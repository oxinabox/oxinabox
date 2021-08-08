using Cascadia
using Gumbo
using CSV
using Markdown
using Downloads: download

include("piracy.jl")

function main()
    repo_urls = CSV.File(joinpath(dirname(@__DIR__), "data", "repos.csv")).repo
    infos = asyncmap(get_info, repo_urls)
    write_readme(infos)
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
    return ProjectInfo(;
        url,
        user,
        name = text(only(eachmatch(sel"[itemprop='name']", doc.root))),
        description = replace(get_only(sel"meta[name='description']")."content", r" - GitHub - .*"=>""),  # strip github's repeating itself
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

function write_readme(infos=[])
    open(joinpath(dirname(@__DIR__), "README.md"), "w") do fh
        output(x) = show(fh, MIME("text/markdown"), x)
        linebreak() = println(fh, "\n\n")

        output(md"# 🐂 Hi Hi, I am Lyndon")
        output(md"Feel encouraged to reach out to me. I like people.\\")
        output(md"I am very contactable online. I am sure you can find me.\\")
        linebreak()
        

        output(md"GitHub doesn't make it easy to showcase all the projects I am involved in.")
        output(md"Especially with so many being inside various github orgs.")
        output(md"So I am using this profile README.md to experiment with providing something better")
        linebreak()
        output(md"Below you will find a list of projects I am involved in, that I think are particularly cool.")
        output(md"*Note that it is incomplete, and this is currently an experiment.*")
        linebreak()

        foreach(output, infos)

        nothing
    end
end


main()